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

          rabbitmq = RunRabbitRun::Rabbitmq::Base.new(:master)
          rabbitmq.subscribe_to_system_messages "master.#" do | headers, payload |
            call_callback :on_system_message_received, payload["worker"].to_sym, payload["message"].to_sym, payload["data"]
          end

          before_exit do
            rabbitmq.stop
          end

        end
      end
    end
  end
end
