require 'spec_helper'

describe 'worker queues' do
  it 'defines queue' do
    worker = RRR::Processes::Worker.run 'name' do
      queue :input
      def call; end
    end

    worker.queues.size.should == 1
    worker.queues[:input].name.should == :input
    worker.queues[:input].should be_a(RRR::Amqp::Queue)
  end


  context 'sending messages' do
    let(:channel)  { stub(:channel) }
    let(:exchange) { stub(:exchange) }
    let(:queue)    { stub(:queue) }

    before do
      RRR::Utils::System.stub(:ip_address).and_return('1.1.1.1')
      RRR::Amqp.stub(:channel).and_return(channel)
      queue.stub(:bind)
      channel.should_receive(:prefetch)
    end

    it 'uses specified queue name to send messages' do
      worker = RRR::Processes::Worker.run 'name' do
        queue :input, durable: true, name: 'queue_real_name'
        def call
          queues[:input].notify({ some: :data })
        end
      end

      exchange.should_receive(:publish).with("{\"some\":\"data\"}", {
        routing_key: 'queue_real_name',
        headers: {
          created_at: Time.local(2000).to_f,
          pid: Process.pid,
          ip: '1.1.1.1'
        }
      })
      channel.should_receive(:queue).with('queue_real_name', { durable: true }).and_return(queue)
      channel.should_receive(:direct).with('test.rrr.direct').and_return(exchange)

      Timecop.freeze(Time.local(2000)) do
        worker.run
      end
    end

    context 'common options' do
      before do
        exchange.should_receive(:publish).with("{\"some\":\"data\"}", {
          routing_key: 'input',
          headers: {
            created_at: Time.local(2000).to_f,
            pid: Process.pid,
            ip: '1.1.1.1'
          }
        })
      end

      context '#notify' do
        it 'sends message to the direct exchange' do
          worker = RRR::Processes::Worker.run 'name' do
            queue :input, durable: true
            def call
              queues[:input].notify({ some: :data })
            end
          end

          channel.should_receive(:queue).with('input', { durable: true }).and_return(queue)
          channel.should_receive(:direct).with('test.rrr.direct').and_return(exchange)

          Timecop.freeze(Time.local(2000)) do
            worker.run
          end
        end
      end

      context '#notify_one' do
        it 'sends message to the direct exchange' do
          worker = RRR::Processes::Worker.run 'name' do
            queue :input, durable: true
            def call
              queues[:input].notify_one({ some: :data })
            end
          end

          channel.should_receive(:queue).with('input', { durable: true }).and_return(queue)
          channel.should_receive(:direct).with('test.rrr.direct').and_return(exchange)

          Timecop.freeze(Time.local(2000)) do
            worker.run
          end
        end
      end

      context '#notify_all' do
        it 'sends message to the fanout exchange' do
          worker = RRR::Processes::Worker.run 'name' do
            queue :input, durable: true
            def call
              queues[:input].notify_all({ some: :data })
            end
          end

          channel.should_receive(:queue).with('input', { durable: true }).and_return(queue)
          channel.should_receive(:fanout).with('test.rrr.fanout').and_return(exchange)

          Timecop.freeze(Time.local(2000)) do
            worker.run
          end
        end
      end

      context '#notify_where' do
        it 'sends message to the fanout exchange' do
          worker = RRR::Processes::Worker.run 'name' do
            queue :input, durable: true
            def call
              queues[:input].notify_where({ some: :data })
            end
          end

          channel.should_receive(:queue).with('input', { durable: true }).and_return(queue)
          channel.should_receive(:topic).with('test.rrr.topic').and_return(exchange)

          Timecop.freeze(Time.local(2000)) do
            worker.run
          end
        end
      end
    end
  end

end

