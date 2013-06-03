require 'run_rabbit_run/utils/system'

module RRR
  module Amqp
    class Logger

      def info message, &block
        publish "info", message, &block
      end

      def error message, &block
        publish "error", message, &block
      end

      def debug message, &block
        publish "debug", message, &block
      end

    private

      def publish type, message, &block
        send("#{type}_exchange").publish(
          JSON.generate( message: message ),
          headers.merge(routing_key: queue_name_for(type)),
          &block
        )
      end

      def info_exchange
        @info_exchange ||= exchange_for "info"
      end

      def error_exchange
        @error_exchange ||= exchange_for "error"
      end

      def debug_exchange
        @debug_exchange ||= exchange_for "debug"
      end

      def queue_name_for type
        "#{RRR.config[:env]}.system.log.#{type}"
      end

      def exchange_for type
        exchange = RRR::Amqp.channel.fanout("#{RRR.config[:env]}.rrr.log.#{type}", durable: true)

        RRR::Amqp.channel.queue(queue_name_for(type), durable: true).bind(exchange)

        exchange
      end

      def headers
        {
          headers: RRR::Amqp.default_headers
        }
      end

    end
  end
end
