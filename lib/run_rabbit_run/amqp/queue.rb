module RRR
  module Amqp
    class Queue
      attr_accessor :name, :queue_name, :options

      def initialize name, options = {}
        @name       = name
        @options    = options.dup

        @queue_name = @options.delete(:name) || name.to_s
      end

      def notify message, opts = {}, &block
        publish RRR::Amqp.channel.direct(''), message, opts, &block
      end

      def notify_where message, opts = {}, &block
        publish RRR::Amqp.channel.topic(''), message, opts, &block
      end

      def notify_all message, opts = {}, &block
        publish RRR::Amqp.channel.fanout(''), message, opts, &block
      end

      def notify_one message, opts = {}, &block
        publish RRR::Amqp.channel.direct(''), message, opts, &block
      end

      def subscribe opts = {}, &block
        queue = RRR::Amqp.channel.queue(queue_name, options)

        queue.subscribe(opts) do | headers, payload |
          begin
            block.call headers, JSON.parse(payload)
          rescue => e
            RRR.logger.error "#{e.message},\n#{e.backtrace.join("\n")}"
          end
        end
      end

      def unsubscribe
        RRR::Amqp.channel.queue(queue_name, options).unsubscribe
      end

      def status &block
        queue = RRR::Amqp.channel.queue(queue_name, options)

        queue.status do | number_of_messages, number_of_active_consumers |
          begin
            block.call number_of_messages, number_of_active_consumers
          rescue => e
            RRR.logger.error "#{e.message},\n#{e.backtrace.join("\n")}"
          end
        end
      end

    private

      def publish exchange, message, opts = {}, &block
        RRR::Amqp.channel.queue(queue_name, options)

        exchange.publish(JSON.generate(message), headers.merge(opts), &block)
      end

      def headers
        {
          routing_key: queue_name,
          headers: RRR::Amqp.default_headers
        }
      end

    end
  end
end
