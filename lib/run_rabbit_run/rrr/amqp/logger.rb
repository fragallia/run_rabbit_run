module RRR
  module Amqp
    class Logger 
      attr_accessor :name, :options

      def initialize name = 'log'
        @name       = name     
        @queue_name = "#{RunRabbitRun.config[:environment]}.system.log"
      end

      def info message, &block
        exchange.publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: "#{@queue_name}.info"),
          &block
        )
      end

      def error message, &block
        exchange.publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: "#{@queue_name}.error"),
          &block
        )
      end

      def debug message, &block
        exchange.publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: "#{@queue_name}.debug"),
          &block
        )
      end
    private

      def exchange
        @exchange ||= begin
          exchange = RRR::Amqp.channel.fanout('', durable: true)

          RRR::Amqp.channel.queue("#{@queue_name}.info", durable: true)
          RRR::Amqp.channel.queue("#{@queue_name}.error", durable: true)
          RRR::Amqp.channel.queue("#{@queue_name}.debug", durable: true)
          
          exchange
        end
      end

      def headers
        {
          routing_key: @queue_name,
          headers: {
            created_at: Time.now.to_f,
            pid: Process.pid,
            host: Socket.gethostname
          }
        }
      end

    end
  end
end
