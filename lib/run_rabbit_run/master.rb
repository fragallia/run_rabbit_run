require 'run_rabbit_run/workers'
require 'run_rabbit_run/rabbitmq'
require 'run_rabbit_run/rabbitmq/system_messages'
require 'run_rabbit_run/pid'
require 'run_rabbit_run/processes/master'

module RunRabbitRun
  module Master
    extend self

    def master_process
      @master_process ||= begin
        master = RunRabbitRun::Processes::Master.new
        master.pid = Pid.pid

        master
      end
    end

    def start
      master_process.start do
        workers = RunRabbitRun::Workers.new
        workers.start

        add_periodic_timer 5 do
          begin
            workers.check unless exiting? || starting?
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
          begin
            RunRabbitRun.logger.info "[master] got message [#{message}] from [#{from}] with data [#{data.inspect}]"

            case message.to_sym
            when :add_worker
              workers.add(data['worker'])
            when :remove_worker
              workers.remove(data['worker'])
            when :process_started
              workers.worker(from.to_s).pid = data["pid"].to_i
            end
          rescue => e
            RunRabbitRun.logger.error e.message
          end
        end

      end

      Pid.save(master_process.pid)
    end

    def add_worker name
      EventMachine.run do
        rabbitmq = RunRabbitRun::Rabbitmq::Base.new

        system_messages = RunRabbitRun::Rabbitmq::SystemMessages.new(rabbitmq)
        system_messages.publish(:system, :master, :add_worker, { worker: name })

        EventMachine.add_timer(2) do
          rabbitmq.stop
        end
      end
    end

    def remove_worker name
      EventMachine.run do
        rabbitmq = RunRabbitRun::Rabbitmq::Base.new

        system_messages = RunRabbitRun::Rabbitmq::SystemMessages.new(rabbitmq)
        system_messages.publish(:system, :master, :remove_worker, { worker: name })

        EventMachine.add_timer(2) do
          rabbitmq.stop
        end
      end
    end

    def stop
      RunRabbitRun::Processes::Signals.stop_signal(:master, master_process.pid)
      Pid.remove
    end

    def reload
      RunRabbitRun::Processes::Signals.reload_signal(:master, master_process.pid)
    end
  end
end
