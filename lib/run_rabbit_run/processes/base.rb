require 'run_rabbit_run/callbacks'
require 'run_rabbit_run/processes/signals'

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
        if RunRabbitRun::Processes::Signals.running? @pid
          raise "The process [#{@name}] is already running"
        end

        RunRabbitRun.logger.info "[#{@name}] process starting"

        @pid = fork do
          $0 = "[ruby] [RunRabbitRun] #{@name}"

          signals    = []

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
                @exiting = true

                call_callback :before_exit
                EventMachine::add_timer( 10 ) do
                  EventMachine.stop { exit }
                end
              end
            end

            @starting = false
          end

          RunRabbitRun.logger.info "[#{@name}] process finished"
        end

        Process.detach(@pid)

      end

      def starting?
        @starting ||= true
      end

      def exiting?
        @exiting ||= false
      end

      def guid
        "#{@name}-#{@pid}"
      end

      def add_timer seconds, &block
        EventMachine::add_timer( seconds ) do
          block.call
        end
      end

      def add_periodic_timer seconds, &block
        EventMachine::add_periodic_timer( seconds ) do
          block.call
        end
      end
    end
  end
end
