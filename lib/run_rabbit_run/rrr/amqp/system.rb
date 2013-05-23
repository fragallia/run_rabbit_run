module RRR
  module Amqp
    class System 
      def initialize master_name, worker_name
        @master_name       = master_name
        @worker_name       = worker_name
        @master_queue_name = "#{RunRabbitRun.config[:environment]}.system.#{@master_name}"
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
        {
          name: @worker_name,
          created_at: Time.now.to_f,
          pid: Process.pid,
          host: Socket.gethostname
        }
      end

    end
  end
end
