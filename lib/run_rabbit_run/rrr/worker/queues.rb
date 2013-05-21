require 'run_rabbit_run/rrr/amqp/queue'

module RRR
  module Worker
    module Queues
      def queue name, options = {}
        @queues ||= {}
        @queues[name] = RRR::Amqp::Queue.new(name, options)

        @queues
      end

      def queues
        @queues
      end
    end
  end
end
