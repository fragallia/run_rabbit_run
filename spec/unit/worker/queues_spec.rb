require 'spec_helper'

describe 'worker queues' do
  it 'defines queue' do
    worker = RRR::Worker.run 'name' do
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
      RRR::Amqp.stub(:channel).and_return(channel)
      queue.stub(:bind)
      channel.should_receive(:queue).with(:input, { durable: true }).and_return(queue)
      exchange.should_receive(:publish).with("{\"some\":\"data\"}", {
        routing_key: :input,
        headers: {
          created_at: Time.local(2000).to_f,
          pid: Process.pid
        }
      })
    end

    context '#notify' do
      it 'sends message to the direct exchange' do
        worker = RRR::Worker.run 'name' do
          queue :input, durable: true
          def call
            queues[:input].notify({ some: :data })
          end
        end

        channel.should_receive(:direct).with('').and_return(exchange)

        Timecop.freeze(Time.local(2000)) do
          worker.run
        end
      end
    end

    context '#notify_one' do
      it 'sends message to the direct exchange' do
        worker = RRR::Worker.run 'name' do
          queue :input, durable: true
          def call
            queues[:input].notify_one({ some: :data })
          end
        end

        channel.should_receive(:direct).with('').and_return(exchange)

        Timecop.freeze(Time.local(2000)) do
          worker.run
        end
      end
    end

    context '#notify_all' do
      it 'sends message to the fanout exchange' do
        worker = RRR::Worker.run 'name' do
          queue :input, durable: true
          def call
            queues[:input].notify_all({ some: :data })
          end
        end

        channel.should_receive(:fanout).with('').and_return(exchange)

        Timecop.freeze(Time.local(2000)) do
          worker.run
        end
      end
    end

    context '#notify_where' do
      it 'sends message to the fanout exchange' do
        worker = RRR::Worker.run 'name' do
          queue :input, durable: true
          def call
            queues[:input].notify_where({ some: :data })
          end
        end

        channel.should_receive(:topic).with('').and_return(exchange)

        Timecop.freeze(Time.local(2000)) do
          worker.run
        end
      end
    end
  end

end

