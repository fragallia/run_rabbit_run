require 'run_rabbit_run/processes/base'

module RunRabbitRun

  module Processes
    class Master < Base

      define_callback :on_system_message_received

      def initialize name = :master
        @name = name
      end

      def start &block
        super do
          instance_exec &block

          rabbitmq = RunRabbitRun::Rabbitmq::Base.new
          system_messages = RunRabbitRun::Rabbitmq::SystemMessages.new(rabbitmq)

          system_messages.subscribe "master.#" do | headers, payload |
            call_callback :on_system_message_received, payload["from"].to_sym, payload["message"].to_sym, payload["data"]
          end

          before_exit do
            rabbitmq.stop
          end

        end
      end
    end
  end
end
