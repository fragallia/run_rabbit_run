module RRR
  module Amqp
    class System 
      def initialize master_name, worker_options
        @master_name       = master_name
        @worker_options    = worker_options
        @master_queue_name = "#{RRR.config[:env]}.system.#{@master_name}"
      end

      def notify message, &block
        RRR::Amqp.channel.direct('').publish(
          JSON.generate( message: message ),
          options.merge({ headers: headers }),
          &block
        )
      end

    private

      def options
        {
          routing_key: @master_queue_name,
          persistent: true,
        }
      end

      def headers
        RRR::Amqp.default_headers.merge(@worker_options)
      end

    end
  end
end
