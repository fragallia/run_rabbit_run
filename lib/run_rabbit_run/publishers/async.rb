require 'bunny'
require 'bson'

module RunRabbitRun
  module Publishers
    class Async
      def send_message(queue, payload)
        exchange.publish(BSON.serialize(payload).to_s, :routing_key => queue.name)
      end

      def exchange
        @exchange ||= RunRabbitRun::Consumer.channel.direct('')
      end
    end
  end
end
