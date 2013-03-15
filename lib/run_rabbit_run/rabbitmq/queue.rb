module RunRabbitRun
  module Rabbitmq
    class Queue
      attr_accessor :name, :options, :queue
      def initialize(name, options = {})
        @name = name
        @options = options
        @queue = RunRabbitRun::Rabbitmq.channel.queue(@name, @options)
      end

      def subscribe &block
        @queue.subscribe &block
      end
    end
  end
end
