require 'run_rabbit_run/processes/base'

module RunRabbitRun
  module Processes
    class Worker < Base

      def initialize name, master_guid, options
        @options     = options
        @master_guid = master_guid
        super name
      end

      def start &block
        super do
          instance_exec &block if block_given?

          rabbitmq = RunRabbitRun::Rabbitmq::Base.new
          system_messages = RunRabbitRun::Rabbitmq::SystemMessages.new(rabbitmq)

          system_messages.publish(@name, "master.#{@master_guid}", :process_started, { pid: Process.pid } )

          if @options[:processes] == 0
            add_timer 1 do
              rabbitmq.instance_eval File.read(@options[:path]), @options[:path]

              system_messages.publish(@name, "master.#{@master_guid}", :process_quit)
              rabbitmq.stop
            end
          else

            rabbitmq.on_message_received do | queue |
              system_messages.publish(@name, "master.#{@master_guid}", :message_received, { queue: queue.name } ) if @options[:log_to_master]
            end
            rabbitmq.on_message_processed do | queue |
              system_messages.publish(@name, "master.#{@master_guid}", :message_processed, { queue: queue.name } ) if @options[:log_to_master]
            end
            rabbitmq.on_error do | queue, e |
              RunRabbitRun.logger.error "[#{@name}] #{e.message} \n#{e.backtrace.join("\n")}"
              #system_messages.publish( @name, :master, :error,
              #  {
              #    queue: queue.name,
              #    exception: { message: e.message, backtrace: e.backtrace }
              #  }
              #) if @options[:log_to_master]
            end

            add_timer 1 do
              begin
                rabbitmq.instance_eval File.read(@options[:path]), @options[:path]
              rescue => e
                RunRabbitRun.logger.error "[#{@name}] #{e.message} \n#{e.backtrace.join("\n")}"
              end
            end

            before_exit do
              system_messages.publish(@name, "master.#{@master_guid}", :process_quit)
              rabbitmq.stop
            end
          end
        end
      end
    end
  end
end
