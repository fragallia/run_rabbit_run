module RunRabbitRun
  module Rabbitmq
    class SystemMessages
      def initialize(rabbitmq)
        @rabbitmq = rabbitmq
      end

      def subscribe routing_key, &block
        system_queue.bind(system_exchange, routing_key: "profile.#{RunRabbitRun.config[:environment]}.#{routing_key}")
        system_queue.subscribe do | headers, payload |
          block.call(headers, JSON.parse(payload))
        end
      end

      def publish from, target, message, data = {}
        system_exchange.publish(
          JSON.generate({
            from: from,
            message: message,
            data: { time: Time.now.to_f }.merge(data)
          }),
          routing_key: "profile.#{RunRabbitRun.config[:environment]}.#{target}")
      end

    private

      def system_queue
        @system_queue ||= @rabbitmq.channel.queue("profile.#{RunRabbitRun.config[:environment]}", auto_delete: false)
      end

      def system_exchange
        @system_exchange ||= @rabbitmq.channel.topic("runrabbitrun.system", durable: true)
      end

    end
  end
end
