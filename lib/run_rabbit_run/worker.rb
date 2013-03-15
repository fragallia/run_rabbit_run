require 'run_rabbit_run/rabbitmq'

module RunRabbitRun
  class Worker
    attr_accessor :name, :pid, :status
    def initialize(name)
      @name = name

      @status = :unknown
    end

    def display_name
      options[:name] || @name
    end

    def options
      RunRabbitRun.config[:workers][name]
    end

    def run

      raise "The worker <#{display_name}> is already running" if self.running?

      RunRabbitRun.logger.info "[#{display_name}] worker starting"

      @pid = fork do
        $0 = "[ruby] [RunRabbitRun] [#{display_name}] worker process"
        signals = []

        Signal.trap(RunRabbitRun::SIGNAL_EXIT)   { signals << RunRabbitRun::SIGNAL_EXIT   }

        EventMachine.run do
          rabbitmq = RunRabbitRun::Rabbitmq::Base.new(@name)
          rabbitmq.system_message(:master, :process_started)
          rabbitmq.instance_eval File.read(options[:path]), options[:path]

          EventMachine::add_periodic_timer( 0.5 ) do
            if signals.include?( RunRabbitRun::SIGNAL_EXIT )
              rabbitmq.system_message(:master, :process_quit)
              rabbitmq.stop
            end
          end
        end

        RunRabbitRun.logger.info "[#{display_name}] worker process finished"
      end

      Process.detach(@pid)
    end

    def stop
      if running?
        RunRabbitRun.logger.info "[#{display_name}] send exit signal to worker process"
        Process.kill(RunRabbitRun::SIGNAL_EXIT, pid)

        Pid.remove
      else
        RunRabbitRun.logger.debug "can't stop process, not running"
      end
    end

    def kill
      if self.running?
        RunRabbitRun.logger.info "[#{display_name}] kill worker process"
        Process.kill(RunRabbitRun::SIGNAL_KILL, pid)

        Pid.remove
      else
        RunRabbitRun.logger.debug "can't kill process, not running"
      end
    end

    def running?
      return false unless pid

      begin
        Process.getpgid(pid.to_i )

        return true
      rescue Errno::ESRCH
      rescue Exception => e
        RunRabbitRun.logger.error "#{e}, #{e.backtrace.join("\n")}"
      end

      return false
    end
  end
end
