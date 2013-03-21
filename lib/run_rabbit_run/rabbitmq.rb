require 'run_rabbit_run/callbacks'

module RunRabbitRun
  module Rabbitmq
    class Base
      include RunRabbitRun::Callbacks
      
      def initialize
        channel.on_error(&method(:handle_channel_exception))
      end

      define_callback :on_message_received
      define_callback :on_message_processed

      def subscribe(queue, options = {}, &block)
        opts = options.dup
        time_logging   = opts.delete(:time_logging) || false

        queue.subscribe do | header, payload |
          RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] started" if time_logging
          call_callback :on_message_received, queue

          instance_exec(header, JSON.parse(payload), &block)

          call_callback :on_message_processed, queue
          RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] finished" if time_logging
        end
      end

      def publish(queue, data)
        exchange.publish JSON.generate(data), :routing_key => queue.name
      end

      def connection
        @connection ||= AMQP.connect(host: '127.0.0.1', username: "guest", password: "guest")
      end

      def channel
        @channel    ||= AMQP::Channel.new(connection, AMQP::Channel.next_channel_id, auto_recovery: true)
      end

      def exchange
        @exchange    ||= channel.direct('')
      end

      def stop
        connection.close {
          EventMachine.stop { exit }
        }
      end

    private

      def handle_channel_exception(channel, channel_close)
        RunRabbitRun.logger.error "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"

        stop
      end # handle_channel_exception
    end
  end
end
