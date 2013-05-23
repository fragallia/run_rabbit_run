module RRR
  module Amqp
    class Queue
      attr_accessor :name, :options

      def initialize name, options = {}
        @name = name     
        @options = options
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
        queue = RRR::Amqp.channel.queue(name, options)

        queue.subscribe(opts) do | headers, payload |
          block.call headers, JSON.parse(payload)
        end
      end

      def unsubscribe
        RRR::Amqp.channel.queue(name, options).unsubscribe
      end

    private

      def publish exchange, message, opts = {}, &block
        RRR::Amqp.channel.queue(name, options)

        exchange.publish(JSON.generate(message), headers.merge(opts), &block)
      end

      def headers
        {
          routing_key: name,
          headers: {
            created_at: Time.now.to_f,
            pid: Process.pid
          }
        }
      end

    end
  end
end
