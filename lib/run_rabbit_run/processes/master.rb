module RunRabbitRun
  require 'run_rabbit_run/pid'

  module Processes
    module Master
      extend self

      SIGNALS = []

      def start &block
        raise 'The master is already running' if self.running?

        pid = fork do
          $0 = "[ruby] [RunRabbitRun] Master process"

          Signal.trap(RunRabbitRun::SIGNAL_EXIT)   { SIGNALS << RunRabbitRun::SIGNAL_EXIT   }
          Signal.trap(RunRabbitRun::SIGNAL_RELOAD) { SIGNALS << RunRabbitRun::SIGNAL_RELOAD }

          EventMachine.run do
            instance_exec &block

            EventMachine::add_periodic_timer( 0.5 ) do
              if SIGNALS.include?( RunRabbitRun::SIGNAL_RELOAD )
                SIGNALS.delete( RunRabbitRun::SIGNAL_RELOAD )

                @before_reload_callbacks.each { | callback | callback.call }
              end
              if SIGNALS.include?( RunRabbitRun::SIGNAL_EXIT )
                @before_exit_callbacks.each { | callback | callback.call }
              end
            end
          end

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

      def on_system_message_received &block
        rabbitmq = RunRabbitRun::Rabbitmq::Base.new(:master)
        rabbitmq.subscribe_to_system_messages "master.#" do | headers, payload |
          block.call(payload["worker"].to_sym, payload["message"].to_sym, payload["data"])
        end

        before_exit do
          rabbitmq.stop
        end
      end

      def before_exit &block
        @before_exit_callbacks ||= []
        @before_exit_callbacks << block
      end

      def before_reload &block
        @before_reload_callbacks ||= []
        @before_reload_callbacks << block
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
end
