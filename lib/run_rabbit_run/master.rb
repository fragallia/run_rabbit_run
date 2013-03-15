module RunRabbitRun
  require 'run_rabbit_run/workers'
  require 'run_rabbit_run/processes/master'

  module Master
    extend self
    
    def start
      RunRabbitRun::Processes::Master.start do
        workers = RunRabbitRun::Workers.new
        workers.start

        before_exit do
          workers.stop
        end

        before_reload do
          workers.reload
        end

        on_system_message_received do | from, message, data |
          workers.status(from, message)
        end

      end
    end

    def stop
      RunRabbitRun::Processes::Master.stop
    end

    def reload
      RunRabbitRun::Processes::Master.reload
    end
  end
end
