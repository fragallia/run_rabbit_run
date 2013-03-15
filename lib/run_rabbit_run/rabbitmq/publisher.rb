module RunRabbitRun
  module Rabbitmq
    class Publisher
      attr_accessor :bunny

      def bunny
        @bunny ||= begin
          bunny = Bunny.new
          bunny.start
          
          bunny
        end
      end

      def exchange
        @exchange ||= bunny.exchange("")
      end

      def send(queue, data, options = {})
        exchange.publish(JSON.generate(data), :key => queue.name)
      end

      def stop
        bunny.stop if @bunny
      end
    end
  end
end
