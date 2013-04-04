module RunRabbitRun
  module Rabbitmq
    class SystemMessages
      def initialize(rabbitmq)
        @rabbitmq        = rabbitmq
        @system_queue    = @rabbitmq.channel.queue("profile.#{RunRabbitRun.config[:environment]}", durable: true, auto_delete: false)
        @system_exchange = @rabbitmq.channel.topic("runrabbitrun.system", durable: true)
      end

      def subscribe routing_key, &block
        @system_queue.
            bind(@system_exchange, routing_key: "profile.#{RunRabbitRun.config[:environment]}.#{routing_key}").
            subscribe do | headers, payload |
          block.call(headers, JSON.parse(payload))
        end
      end

      def publish from, target, message, data = {}
        @system_exchange.publish(
          JSON.generate({
            from: from,
            message: message,
            data: { time: Time.now.to_f }.merge(data)
          }),
          routing_key: "profile.#{RunRabbitRun.config[:environment]}.#{target}")
      end

    end
  end
end
