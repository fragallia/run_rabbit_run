require 'bunny'
require 'bson'

module RunRabbitRun
  module Publishers
    class Sync
      attr_accessor :queues

      def initialize(queue_names)
        # start a communication session with the amqp server
        bunny.start

        # declare a queues
        queues = {}
        queue_names.each do | name |
          queues[name] = bunny.queue(name, :auto_delete => false)
        end

        exchange
      end

      def bunny
        @bunny ||= Bunny.new
      end

      def exchange
        @exchange ||= bunny.exchange("")
      end

      def send_message(queue_name, payload)
        # publish a message to the exchange which then gets routed to the queue
        exchange.publish(BSON.serialize(payload).to_s, :key => queue_name)
      end

      def stop
        # close the connection
        bunny.stop
      end

    end
  end
end
