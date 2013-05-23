require 'run_rabbit_run/utils/callbacks'
require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/system'
require 'run_rabbit_run/amqp/logger'
require 'run_rabbit_run/worker/queues'
require 'run_rabbit_run/worker/subscribe'
require 'run_rabbit_run/worker/processes'
require 'run_rabbit_run/worker/add_dependency'

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

      include RRR::Utils::Callbacks

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
          RRR::Amqp.channel.prefetch processes[:prefetch]
          RRR.logger = RRR::Amqp::Logger.new

#TODO test when error
          on_error do | e, data |
            RRR.Logger.error e.message
          end

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

        Signal.trap(RRR::SIGNAL_EXIT)   { signals << RRR::SIGNAL_EXIT   }
        Signal.trap(RRR::SIGNAL_INT)    { signals << RRR::SIGNAL_EXIT   }
        Signal.trap(RRR::SIGNAL_TERM)   { signals << RRR::SIGNAL_EXIT   }
        Signal.trap(RRR::SIGNAL_RELOAD) { signals << RRR::SIGNAL_RELOAD }

        EM::add_periodic_timer( 0.5 ) do
          reload if signals.delete( RRR::SIGNAL_RELOAD )
          stop   if signals.delete( RRR::SIGNAL_EXIT )
        end
      end
    end
  end
end
