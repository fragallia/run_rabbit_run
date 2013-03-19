require 'run_rabbit_run/callbacks'

module RunRabbitRun
  module Processes
    class Base
      include RunRabbitRun::Callbacks

      define_callback :before_exit
      define_callback :before_reload

      attr_accessor :pid, :name

      def initialize name
        @name = name
      end

      def start &block
        raise "The process [#{@name}] is already running" if running?

        RunRabbitRun.logger.info "[#{@name}] process starting"

        @pid = fork do
          $0 = "[ruby] [RunRabbitRun] #{@name}"

          signals = []

          Signal.trap(RunRabbitRun::SIGNAL_EXIT)   { signals << RunRabbitRun::SIGNAL_EXIT   }
          Signal.trap(RunRabbitRun::SIGNAL_RELOAD) { signals << RunRabbitRun::SIGNAL_RELOAD }

          EventMachine.run do

            instance_exec &block

            EventMachine::add_periodic_timer( 0.5 ) do
              if signals.include?( RunRabbitRun::SIGNAL_RELOAD )
                signals.delete( RunRabbitRun::SIGNAL_RELOAD )

                call_callback :before_reload
              end
              if signals.include?( RunRabbitRun::SIGNAL_EXIT )
                call_callback :before_exit
                #?! there could be amqp stop in process
                sleep 1
                EventMachine.stop { exit }
              end
            end
          end

          RunRabbitRun.logger.info "[#{@name}] process finished"
        end

        Process.detach(@pid)
      end

      def add_periodic_timer seconds, &block
        EventMachine::add_periodic_timer( seconds ) do
          block.call
        end
      end

      def stop
        send_signal(name, RunRabbitRun::SIGNAL_EXIT)
      end

      def reload
        send_signal(name, RunRabbitRun::SIGNAL_RELOAD)
      end

      def send_signal(name, signal)
        if running?
          RunRabbitRun.logger.info "[#{name}] send #{signal_name(signal)} signal to process"
          Process.kill(signal, @pid)
        else
          RunRabbitRun.logger.debug "[#{name}] is not running"
        end
      end

      def signal_name code
        case code
        when 'QUIT'
          'exit'
        when 'USR1'
          'reload'
        when 'KILL'
          'kill'
        end
      end

      def running?
        return false unless @pid

        begin
          Process.getpgid(@pid.to_i )

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
