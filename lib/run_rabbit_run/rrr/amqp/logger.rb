module RRR
  module Amqp
    class Logger 

      def initialize
        @queue_name = "#{RunRabbitRun.config[:environment]}.system.log"
      end

      def info message, &block
        info_exchange.publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: "#{@queue_name}.info"),
          &block
        )
      end

      def error message, &block
        error_exchange.publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: "#{@queue_name}.error"),
          &block
        )
      end

      def debug message, &block
        debug_exchange.publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: "#{@queue_name}.debug"),
          &block
        )
      end

    private

      def info_exchange
        @exchange ||= begin
          exchange = RRR::Amqp.channel.fanout('rrr.log.info', durable: true)

          RRR::Amqp.channel.queue("#{@queue_name}.info", durable: true).bind(exchange)
          
          exchange
        end
      end

      def error_exchange
        @exchange ||= begin
          exchange = RRR::Amqp.channel.fanout('rrr.log.error', durable: true)

          RRR::Amqp.channel.queue("#{@queue_name}.error", durable: true).bind(exchange)
          
          exchange
        end
      end

      def debug_exchange
        @exchange ||= begin
          exchange = RRR::Amqp.channel.fanout('rrr.log.debug', durable: true)

          RRR::Amqp.channel.queue("#{@queue_name}.debug", durable: true).bind(exchange)
          
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
