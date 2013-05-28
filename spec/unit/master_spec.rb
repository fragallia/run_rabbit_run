require 'spec_helper'

describe 'master' do
  it 'generates guid' do
    RRR::Utils::System.should_receive(:ip_address).and_return('1.1.1.1')

    master = RRR::Master::Base.new

    master.name.should       == "master.1.1.1.1"
    master.queue_name.should == "test.system.master.1.1.1.1"
  end

  context '#RRR::Master.run' do
    include EventedSpec::SpecHelper

    let(:channel)  { stub(:channel) }
    let(:queue)    { stub(:queue) }

    before do
      RRR::Amqp.stub(:channel).and_return(channel)
      channel.stub(:prefetch)
    end

    it 'listens to the signals' do
      master = RRR::Master::Base.new

      master.stub(:listen_to_worker_start)
      master.stub(:listen_to_worker_stop)
      master.stub(:listen_to_workers)

      Signal.should_receive(:trap).with(RRR::Utils::Signals::QUIT)
      Signal.should_receive(:trap).with(RRR::Utils::Signals::INT)
      Signal.should_receive(:trap).with(RRR::Utils::Signals::TERM)

      em do
        master.run

        master.stop
      end
    end

    it 'creates and subscribes to the master queue' do
      master = RRR::Master::Base.new

      master.stub(:listen_to_worker_start)
      master.stub(:listen_to_worker_stop)

      channel.should_receive(:queue).with(master.queue_name, auto_delete: true).and_return(queue)
      queue.should_receive(:subscribe)

      em do
        master.run

        done
      end
    end

    context 'workers' do
      it 'subscribes to the system.env.worker.start queue' do
        master = RRR::Master::Base.new

        master.stub(:listen_to_workers)
        master.stub(:listen_to_worker_stop)

        channel.should_receive(:queue).with('test.system.worker.start', durable: true).and_return(queue)
        queue.should_receive(:subscribe).with( ack: true )

        em do
          master.run

          done
        end
      end

      it 'runs worker wenn TIME COMES' do
        master = RRR::Master::Base.new

        master.stub(:listen_to_workers)
        master.stub(:listen_to_worker_stop)

        channel.should_receive(:queue).with('test.system.worker.start', durable: true).and_return(queue)
        queue.
          should_receive(:subscribe).
          with( ack: true ).
          and_yield(stub(:headers, ack: 'something'), JSON.generate(code: 'worker code'))

        RRR::WorkerRunner.should_receive(:build).with(master.name, 'worker code')

        em do
          master.run

          done
        end
      end

      it 'rejects message and unsubscribes from the queue if capacity is reached' do
        master = RRR::Master::Base.new

        master.capacity = 0

        master.stub(:listen_to_workers)
        master.stub(:listen_to_worker_stop)

        headers = stub(:headers)
        channel.should_receive(:queue).with('test.system.worker.start', durable: true).twice.and_return(queue)
        queue.
          should_receive(:subscribe).
          with( ack: true ).
          and_yield(headers, JSON.generate(code: 'worker code'))

        headers.should_receive(:reject).with( requeue: true )
        queue.should_receive(:unsubscribe)

        em do
          master.run

          done
        end
      end

      it 'stops worker' do
        master = RRR::Master::Base.new

        master.running_workers = { 'name' => [1111, 22222] }

        master.stub(:listen_to_workers)
        master.stub(:listen_to_worker_start)

        channel.should_receive(:queue).with('test.system.worker.stop', durable: true).and_return(queue)
        queue.
          should_receive(:subscribe).
          with( ack: true ).
          and_yield(stub(:headers, ack: 'something'), JSON.generate(name: 'name'))

        RRR::WorkerRunner.should_receive(:stop).with(1111)

        em do
          master.run

          done
        end
      end

      it 'rejects message is there no worker with this name' do

        master = RRR::Master::Base.new

        master.stub(:listen_to_workers)
        master.stub(:listen_to_worker_start)

        headers = stub(:headers)
        channel.should_receive(:queue).with('test.system.worker.stop', durable: true).and_return(queue)
        queue.
          should_receive(:subscribe).
          with( ack: true ).
          and_yield(headers, JSON.generate(code: 'worker code'))

        headers.should_receive(:delivery_tag).and_return(1)
        headers.should_receive(:reject).with( requeue: true )

        em do
          master.run

          done
        end
     end

      context 'worker messages' do
        it 'checks if the worker is started and saves it' do
          master = RRR::Master::Base.new

          master.stub(:listen_to_worker_start)
          master.stub(:listen_to_worker_stop)

          RRR::Amqp::Logger.any_instance.stub(:info)
          headers = stub(:headers, headers: { 'name' => 'worker_name', 'pid' => 1111 } )
          channel.should_receive(:queue).with(master.queue_name, auto_delete: true).and_return(queue)
          queue.should_receive(:subscribe).and_yield(headers, JSON.generate(message: :started))

          em do
            master.run

            master.running_workers.should == { 'worker_name' => [ 1111 ] }

            done
          end
        end

        it 'checks if the worker is finished and removes it' do
          master = RRR::Master::Base.new

          master.running_workers = { 'worker_name' => [1111, 22222] }

          master.stub(:listen_to_worker_start)
          master.stub(:listen_to_worker_stop)

          RRR::Amqp::Logger.any_instance.stub(:info)
          headers = stub(:headers, headers: { 'name' => 'worker_name', 'pid' => 1111 } )
          channel.should_receive(:queue).with(master.queue_name, auto_delete: true).and_return(queue)
          queue.should_receive(:subscribe).and_yield(headers, JSON.generate(message: :finished))

          em do
            master.run

            master.running_workers.should == { 'worker_name' => [ 22222 ] }

            done
          end
        end
      end
    end
  end
end

