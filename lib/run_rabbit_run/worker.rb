require 'run_rabbit_run/rabbitmq'
require 'run_rabbit_run/rabbitmq/system_messages'
require 'run_rabbit_run/processes/worker'

module RunRabbitRun
  class Worker
    attr_accessor :name, :status
    def initialize(name)
      @name = name

      @status = :unknown
    end

    def worker_process
      @worker_process ||= RunRabbitRun::Processes::Worker.new(@name)
    end

    def run options
      worker_process.start do

        rabbitmq = RunRabbitRun::Rabbitmq::Base.new
        system_messages = RunRabbitRun::Rabbitmq::SystemMessages.new(rabbitmq)

        system_messages.send(@name, :master, :process_started)

        rabbitmq.on_message_received do | queue |
          system_messages.send(@name, :master, :message_received, { queue: queue.name } ) if options[:log_to_master]
        end
        rabbitmq.on_message_processed do | queue |
          system_messages.send(@name, :master, :message_processed, { queue: queue.name } ) if options[:log_to_master]
        end 

        rabbitmq.instance_eval File.read(options[:path]), options[:path]

        before_exit do
          system_messages.send(@name, :master, :process_quit)
          rabbitmq.stop
        end

      end
    end

    def stop
      worker_process.stop
    end

    def kill
      worker_process.kill
    end

    def running?
      worker_process.running?
    end
  
  end
end
