require 'spec_helper'

#RRR::Worker.run 'worker_name_1' do
#  add_dependency 'redis'
#  add_dependency 'mongodb', "0.0.6", require: true
#  add_dependency 'github_repository', git: 'git@github.com:fragallia/run_rabbit_run.git'
#  add_dependency 'local_repository', path: 'path/to/repository'
#
#  #adapter :redis, RRR::RedisAdapter
#  #adapter :mongo, RRR::MongoDbAdapter
#
#  processes max: 5, min: 1, desirable: 3, capacity: 10, prefetch: 3
#
#  queue :output, durable: true
#  queue :input, durable: true
#
#  subscribe :input, ack: true
#
#  def call headers, data
#    queues[:output].notify({ some: :data })
#  end
#end

describe 'worker' do
  context '#RRR::Worker.run' do
    context 'callbacks' do
      #TODO test callbacks
    end

    context 'subscribes' do
      let(:channel)  { stub(:channel) }
      let(:queue)    { stub(:queue) }

      it 'subscribes queue if subscibe is given and receives one message' do
        worker = RRR::Worker.run 'name' do
          queue :input, durable: true

          subscribe :input, ack: true
          def call headers, data
            stop
          end
        end

        RRR::Amqp.stub(:channel).and_return(channel)
        channel.should_receive(:prefetch)
        channel.should_receive(:queue).with(:input, durable: true).and_return(queue)
        queue.should_receive(:subscribe).with(ack: true).and_yield('headers', JSON.generate(some: :data))
        worker.should_receive(:call).with('headers', 'some' => 'data').and_call_original

        worker.run
      end
    end

    context 'validations' do
      it 'raises error if no queues are defined' do
        worker = RRR::Worker.run 'name' do
          subscribe :input, ack: true
          def call headers, data; end
        end

        expect do 
          worker.run
        end.to raise_error('Please define the queue subscribe to')
      end

      it 'raises error if no subscription queue is defined' do
        worker = RRR::Worker.run 'name' do
          queue :output
          subscribe :input, ack: true
          def call headers, data; end
        end

        expect do 
          worker.run
        end.to raise_error('Please define the queue subscribe to')
      end

      it 'raises exception if name have something else than letters, numbers and _ ' do
        expect do
          RRR::Worker.run 'name.somethin' do
            def call; end
          end
        end.to raise_error('Name can contain only letters, numbers and _')
      end

      it 'raises exception if no block given' do
        expect do
          RRR::Worker.run 'name_something'
        end.to raise_error('You need to pas block to the RRR::Worker.run method!')
      end

      it 'raises exception if no call method given' do
        expect do
          RRR::Worker.run 'name' do
          end
        end.to raise_error('You need to define call method')
      end
    end
  end
end

