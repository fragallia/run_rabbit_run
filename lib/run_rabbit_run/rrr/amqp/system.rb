module RRR
  module Amqp
    class System 
      def initialize master_name, worker_name
        @master_name       = master_name
        @worker_name       = worker_name
        @master_queue_name = "#{RunRabbitRun.config[:environment]}.system.#{@master_name}"
      end

      def exchange
        @exchange ||= begin
          exchange = RRR::Amqp.channel.topic("rrr.system", durable: true)

          queue    = RRR::Amqp.channel.queue(@master_queue_name, durable: true)
          queue.bind(exchange, routing_key: @master_queue_name)
          
          exchange
        end
      end

      def notify message, &block
        exchange.publish(JSON.generate( message: message ), options.merge({ headers: headers }), &block)
      end

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
          pid: Process.pid
        }
      end

    end
  end
end
