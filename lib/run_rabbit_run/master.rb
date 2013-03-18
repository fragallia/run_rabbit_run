module RunRabbitRun
  require 'run_rabbit_run/workers'
  require 'run_rabbit_run/pid'
  require 'run_rabbit_run/processes/master'

  module Master
    extend self

    def master_process
      @@master_process ||= begin
        master = RunRabbitRun::Processes::Master.new
        master.pid = Pid.pid
       
        master
      end
    end
    
    def start
      master_process.start do
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

      Pid.save(master_process.pid)
    end

    def stop
      master_process.stop
      Pid.remove
    end

    def reload
      master_process.reload
    end
  end
end
