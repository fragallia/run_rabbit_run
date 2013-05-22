require 'run_rabbit_run/callbacks'
require 'run_rabbit_run/rrr/amqp'
require 'run_rabbit_run/rrr/amqp/system'
require 'run_rabbit_run/rrr/worker/queues'
require 'run_rabbit_run/rrr/worker/subscribe'
require 'run_rabbit_run/rrr/worker/processes'
require 'run_rabbit_run/rrr/worker/add_dependency'

module RRR
  module Worker

    def self.run name, &block
      raise 'Name can contain only letters, numbers and _' unless !!(name =~ %r{^[\w]+$})
      if block_given?
        worker = RRR::Worker::Base.new(name)
        worker.load &block

        worker
      else
        raise 'You need to pas block to the RRR::Worker.run method!'
      end
    end

    class Base
      include RRR::Worker::Processes
      include RRR::Worker::Queues
      include RRR::Worker::Subscribe
      include RRR::Worker::AddDependency

      include RunRabbitRun::Callbacks

      define_callback :on_start,
                      :on_exit,
                      :on_reload,
                      :on_error,
                      :on_message_received,
                      :on_message_processed

      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def load &block
        instance_exec &block

        raise 'You need to define call method' unless methods.include?(:call)
      end

      def run options = {}
        raise 'Please define the queue subscribe to' if @subscribe && (!queues || (queues && !queues[@subscribe[:queue]]))

        EM.run do
          watch_signals
          call_callback :on_start

          if @subscribe
            queues[@subscribe[:queue]].subscribe(@subscribe[:options]) do | headers, payload |
              begin
                call_callback :on_message_received, { payload: payload, headers: headers }

                call headers, payload

                call_callback :on_message_processed, { payload: payload, headers: headers }
              rescue => e
                call_callback :on_error, e, { payload: payload, headers: headers }
              end
            end
          else
            call
            stop
          end
        end
      end

      def start options = {}
        run options
      end

      def stop
        call_callback :on_exit

        RRR::Amqp.stop
      end

      def reload
        call_callback :on_reload
      end

    private

      def watch_signals
        signals    = []

        Signal.trap(RunRabbitRun::SIGNAL_EXIT)   { signals << RunRabbitRun::SIGNAL_EXIT   }
        Signal.trap(RunRabbitRun::SIGNAL_INT)    { signals << RunRabbitRun::SIGNAL_EXIT   }
        Signal.trap(RunRabbitRun::SIGNAL_TERM)   { signals << RunRabbitRun::SIGNAL_EXIT   }
        Signal.trap(RunRabbitRun::SIGNAL_RELOAD) { signals << RunRabbitRun::SIGNAL_RELOAD }

        EM::add_periodic_timer( 0.5 ) do
          reload if signals.delete( RunRabbitRun::SIGNAL_RELOAD )
          stop   if signals.delete( RunRabbitRun::SIGNAL_EXIT )
        end
      end
    end
  end
end
