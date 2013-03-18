module RunRabbitRun
  module Rabbitmq
    require 'run_rabbit_run/rabbitmq/publisher'

    class Base
      def initialize(name)
        @name = name
        system_message(:master, :process_started) unless name == :master
      end

      def subscribe(queue, options = {}, &block)
        opts = options.dup
        time_loging   = opts.delete(:time_loging) || false
        log_to_master = opts.delete(:log_to_master) || true

        queue.subscribe do | header, payload |
          RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] started" if time_loging
          system_message(:master, :message_received, { queue: queue.name } ) if log_to_master

          instance_exec(header, JSON.parse(payload), &block)

          system_message(:master, :message_processed, { queue: queue.name } ) if log_to_master
          RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] finished" if time_loging
        end
      end

      def subscribe_to_system_messages routing_key, &block
        system_queue.bind(system_exchange, routing_key: "profile.#{RunRabbitRun.config[:environment]}.#{routing_key}")

        system_queue.subscribe do | headers, payload |
          block.call(headers, JSON.parse(payload))
        end
      end

      def send(queue, data)
        publisher.send(queue, data)
      end

      def connection
        @@connection ||= AMQP.connect(:host => '127.0.0.1')
      end

      def channel
        @@channel    ||= AMQP::Channel.new(connection)
      end

      def publisher
        @@publisher  ||= RunRabbitRun::Rabbitmq::Publisher.new
      end

      def system_message target, message, data = {}
        system_exchange.publish(
          JSON.generate({
            worker: @name,
            message: message,
            data: { time: Time.now.to_f }.merge(data)
          }),
          routing_key: "profile.#{RunRabbitRun.config[:environment]}.#{target}")
      end

      def stop
        system_message(:master, :process_quit) unless @name == :master

        publisher.stop

        connection.close {
          EventMachine.stop { exit }
        }
      end

    private

      def system_queue
        @@system_queue ||= channel.queue("profile.#{RunRabbitRun.config[:environment]}")
      end

      def system_exchange
        @@system_exchange ||= channel.topic("runrabbitrun.system", durable: true)
      end

      def handle_channel_exception(channel, channel_close)
        RunRabbitRun.logger.error "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"

        self.stop
      end # handle_channel_exception
    end
  end
end
