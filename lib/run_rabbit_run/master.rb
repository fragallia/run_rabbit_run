require 'run_rabbit_run/workers'
require 'run_rabbit_run/rabbitmq/system_messages'
require 'run_rabbit_run/pid'
require 'run_rabbit_run/processes/master'

module RunRabbitRun
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

        add_periodic_timer 2 do
          begin
            workers.check
          rescue => e
            RunRabbitRun.logger.error e.message
          end
        end

        before_exit do
          workers.stop
        end

        before_reload do
          workers.reload
        end

        on_system_message_received do | from, message, data |
          RunRabbitRun.logger.info "[master] got message [#{message}] from [#{from}]"
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
