require 'run_rabbit_run/processes/base'
require 'securerandom'

module RunRabbitRun

  module Processes
    class Master < Base

      define_callback :on_system_message_received

      def initialize name = :master
        super name
      end

      def start &block
        super do
          rabbitmq = RunRabbitRun::Rabbitmq::Base.new
          system_messages = RunRabbitRun::Rabbitmq::SystemMessages.new(rabbitmq)

          system_messages.subscribe "master.#{RunRabbitRun::Guid.guid}.#" do | headers, payload |
            call_callback :on_system_message_received, payload["from"].to_sym, payload["message"].to_sym, payload["data"]
          end

          before_exit do
            rabbitmq.stop
          end

          add_timer 1 do
            instance_exec &block
          end

        end
      end
    end
  end
end
