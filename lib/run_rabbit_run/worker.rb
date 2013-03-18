require 'run_rabbit_run/rabbitmq'
require 'run_rabbit_run/processes/worker'

module RunRabbitRun
  class Worker
    attr_accessor :name, :pid, :status
    def initialize(name)
      @name = name

      @status = :unknown
    end

    def worker_process
      @worker_process ||= RunRabbitRun::Processes::Worker.new(@name)
    end

    def run
      worker_process.start do
        options = RunRabbitRun.config[:workers][@name]

        rabbitmq = RunRabbitRun::Rabbitmq::Base.new(@name)
        rabbitmq.instance_eval File.read(options[:path]), options[:path]

        before_exit do
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
