require 'run_rabbit_run/callbacks'

module RunRabbitRun
  module Rabbitmq
    class Base
      include RunRabbitRun::Callbacks

      define_callback :on_message_received
      define_callback :on_message_processed

      def subscribe(queue, options = {}, &block)
        opts = options.dup
        time_logging   = opts.delete(:time_logging) || false

        queue.subscribe(options) do | header, payload |
          RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] started" if time_logging
          call_callback :on_message_received, queue

          instance_exec(header, JSON.parse(payload), &block)

          call_callback :on_message_processed, queue
          RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] finished" if time_logging
        end
      end

      def publish(queue, data)
        exchange.publish JSON.generate(data), routing_key: queue.name
      end

      def publish_sync(queue, data)
        bunny.exchange('').publish(JSON.generate(data), key: queue.name)
      end

      def bunny
        @bunny ||= begin
          require 'bunny'

          bunny = Bunny.new
          bunny.start

          bunny
        end
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
        bunny.stop if @bunny

        connection.close {
          EventMachine.stop { exit }
        }
      end

    end
  end
end
