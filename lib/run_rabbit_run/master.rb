module RunRabbitRun
  require 'run_rabbit_run/workers'
  require 'run_rabbit_run/pid'

  module Master
    extend self
    
    SIGNALS = []

    def start
      raise 'The master is already running' if self.running?

      pid = fork do
        $0 = "[ruby] [RunRabbitRun] Master process"

        config  = RunRabbitRun.config

        workers = RunRabbitRun::Workers.new( config[:workers] || {} )

        Signal.trap(RunRabbitRun::SIGNAL_EXIT)   { SIGNALS << RunRabbitRun::SIGNAL_EXIT   }
        Signal.trap(RunRabbitRun::SIGNAL_RELOAD) { SIGNALS << RunRabbitRun::SIGNAL_RELOAD }

        workers.start

        EventMachine.run do
          #TODO subscribe to master queue to receive status messages from workers

          EventMachine::add_periodic_timer( 0.5 ) do
            if SIGNALS.include?( RunRabbitRun::SIGNAL_RELOAD )
              config = RunRabbitRun.load_config( RunRabbitRun.options[:application_path] )
              workers.reload(config[:workers])

              SIGNALS.delete(RunRabbitRun::SIGNAL_RELOAD)
            end
            EventMachine::stop_event_loop if SIGNALS.include?( RunRabbitRun::SIGNAL_EXIT )
          end
        end
        
        workers.stop

        RunRabbitRun.logger.info '[DONE] exit master process'
      end

      Process.detach(pid)

      Pid.save(pid)
    end

    def stop
      if self.running?
        RunRabbitRun.logger.info 'send exit signal to master process'
        Process.kill(RunRabbitRun::SIGNAL_EXIT, Pid.pid)

        Pid.remove
      else
        RunRabbitRun.logger.error "no process running"
      end
    end

    def reload
      if self.running?
        Process.kill(RunRabbitRun::SIGNAL_RELOAD, Pid.pid)
      else
        RunRabbitRun.logger.error "no process running"
      end
    end

    def running?
      return false unless Pid.pid

      begin
        Process.getpgid(Pid.pid.to_i )

        return true
      rescue Errno::ESRCH
      rescue Exception => e
        RunRabbitRun.logger.error "#{e}, #{e.backtrace.join("\n")}"
      end

      return false
    end
  end
end
