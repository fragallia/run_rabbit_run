module RunRabbitRun
  module Rabbitmq
    class Queue
      attr_accessor :name, :options, :queue
      def initialize(queue, options = {})
        @name = queue.name
        @options = options
        @queue = queue
      end

      def subscribe &block
        @queue.subscribe &block
      end
    end
  end
end
