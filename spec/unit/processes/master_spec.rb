require 'spec_helper'

describe 'master' do
  it 'generates guid' do
    RRR::Utils::System.should_receive(:ip_address).and_return('1.1.1.1')

    master = RRR::Processes::Master::Base.new

    master.name.should       == "master.1.1.1.1"
  end

  context '#RRR::Processes::Master.run' do
    include EventedSpec::SpecHelper

    let(:channel)  { stub(:channel) }
    let(:queue)    { stub(:queue) }

    before do
      RRR::Amqp.stub(:channel).and_return(channel)
      channel.stub(:prefetch)
      channel.stub(:queue).and_return(queue)
      RRR::Utils::System.stub(:ip_address).and_return('1.1.1.1')
    end

    it 'listens to the signals' do
      master = RRR::Processes::Master::Base.new

      queue.stub(:unsubscribe)
      queue.stub(:subscribe)
      Signal.should_receive(:trap).with(RRR::Utils::Signals::QUIT)
      Signal.should_receive(:trap).with(RRR::Utils::Signals::INT)
      Signal.should_receive(:trap).with(RRR::Utils::Signals::TERM)

      em do
        master.run

        master.stop
      end
    end

    it 'creates and subscribes to the master queue' do
      master = RRR::Processes::Master::Base.new

      channel.should_receive(:queue).with("test.system.#{master.name}", auto_delete: true).and_return(queue)
      channel.should_receive(:queue).with("test.system.worker.start", durable: true).and_return(queue)
      channel.should_receive(:queue).with("test.system.worker.stop", durable: true).and_return(queue)

      queue.should_receive(:subscribe).with({})
      queue.should_receive(:subscribe).with(ack: true)
      queue.should_receive(:subscribe).with(ack: true)

      em do
        master.run

        done
      end
    end

    context 'workers' do
      it 'runs worker wenn TIME COMES' do
        master = RRR::Processes::Master::Base.new

        RRR::Processes::WorkerRunner.should_receive(:build).with(master.name, 1, 'worker code')

        master.send(
          :handle_worker_start_message,
          stub(:headers, ack: 'something'),
          { 'name' => 'name', 'capacity' => 10, 'code' => 'worker code' }
        )
      end

      it 'rejects message and unsubscribes from the queue if capacity is reached' do
        master = RRR::Processes::Master::Base.new

        master.workers.capacity = 0

        headers = stub(:headers)
        headers.should_receive(:reject).with( requeue: true )
        queue.should_receive(:unsubscribe).and_yield

        expect {
          master.send(
            :handle_worker_start_message,
            headers,
            { 'name' => 'name', 'capacity' => 10, 'code' => 'worker code' }
          )
        }.to raise_error /Worker can't be run, capacity exceeded/
      end

      it 'stops worker' do
        master = RRR::Processes::Master::Base.new

        master.workers.should_receive(:stop).with('name').and_return('worker')

        master.send(
          :handle_worker_stop_message,
          stub(:headers, ack: 'something'),
          { 'name' => 'name' }
        )
      end

      it 'rejects message is there no worker with this name' do
        master = RRR::Processes::Master::Base.new

        headers = stub(:headers)
        headers.should_receive(:delivery_tag).and_return(1)
        headers.should_receive(:reject).with( requeue: true )

        master.send(
          :handle_worker_stop_message,
          headers,
          { 'name' => 'name' }
        )
     end

      context 'worker messages' do
        it 'checks if the worker is started and saves it' do
          master = RRR::Processes::Master::Base.new

          RRR::Processes::WorkerRunner.stub(:build)

          RRR::Amqp::Logger.any_instance.stub(:info)
          headers = stub(:headers, headers: { 'worker_id' => 1, 'name' => 'worker_name', 'pid' => 1111, 'created_at' => 2012 } )

          exchange = stub(:exchange)
          channel.should_receive(:direct).with('').and_return(exchange)
          exchange.should_receive(:publish) do | message, options, &block |
            JSON.parse(message).should == {
              'action' => 'stats',
              'stats'  => {
                '1' => {
                  'id' => 1,
                  'name' => 'worker_name',
                  'status' => 'started',
                  'master_name' => 'master.1.1.1.1',
                  'capacity' => 10,
                  'created_at' => Time.local(2000).to_f,
                  'pid' => 1111,
                  'stopped_at' => nil,
                  'started_at' => 2012
                }
              },
              'name' => 'master.1.1.1.1'
            }
            options.should == {
              routing_key: "test.system.loadbalancer",
              headers: {
                created_at: Time.local(2000).to_f,
                pid: Process.pid,
                ip: "1.1.1.1"
              }
            }
          end

          Timecop.freeze(Time.local(2000)) do
            master.workers.create 'worker_name', 'code', 10
            master.send(
              :handle_worker_message,
              headers,
              { 'message' => 'started' }
            )
          end
        end

        it 'checks if the worker is finished and removes it' do
          master = RRR::Processes::Master::Base.new

          master.stub(:listen_to_worker_start)
          master.stub(:listen_to_worker_stop)

          RRR::Processes::WorkerRunner.stub(:build)
          RRR::Amqp::Logger.any_instance.stub(:info)

          queue.stub(:subscribe)

          headers = stub(:headers, headers: { 'worker_id' => 1, 'name' => 'worker_name', 'pid' => 1111 } )

          exchange = stub(:exchange)
          channel.should_receive(:direct).with('').and_return(exchange)
          exchange.should_receive(:publish) do | message, options, &block |
            JSON.parse(message).should == {
              'action' => 'stats',
              'stats'  => {},
              'name' => 'master.1.1.1.1'
            }
            options.should == {
              routing_key: "test.system.loadbalancer",
              headers: {
                created_at: Time.local(2000).to_f,
                pid: Process.pid,
                ip: "1.1.1.1"
              }
            }
          end

          Timecop.freeze(Time.local(2000)) do
            master.workers.create 'worker_name', 'code', 10
            master.workers.started 1, 1111, 2012

            master.send(
              :handle_worker_message,
              headers,
              { 'message' => 'finished' }
            )
          end
        end
      end
    end
  end
end

