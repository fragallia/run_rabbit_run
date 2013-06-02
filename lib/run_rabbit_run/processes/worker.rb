require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/system'
require 'run_rabbit_run/amqp/logger'
require 'run_rabbit_run/processes/worker/queues'
require 'run_rabbit_run/processes/worker/subscribe'
require 'run_rabbit_run/processes/worker/processes'
require 'run_rabbit_run/processes/worker/add_dependency'
require 'run_rabbit_run/utils/callbacks'
require 'run_rabbit_run/utils/signals'

module RRR
  module Processes
    module Worker

      def self.run name, &block
        raise 'Name can contain only letters, numbers and _' unless !!(name =~ %r{^[\w]+$})
        if block_given?
          worker = RRR::Processes::Worker::Base.new(name)
          worker.load &block

          worker
        else
          raise 'You need to pas block to the RRR::Processes::Worker.run method!'
        end
      end

      class Base
        include RRR::Processes::Worker::Processes
        include RRR::Processes::Worker::Queues
        include RRR::Processes::Worker::Subscribe
        include RRR::Processes::Worker::AddDependency

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

            on_error do | e, data |
              if RRR.config[:env] == 'test'
                raise e
              else
                RRR.logger.error "#{e.message} : #{e.backtrace}"
              end
            end

            watch_signals

            call_callback :on_start

            if subscribable?
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
          @signals    = []

          Signal.trap(RRR::Utils::Signals::QUIT)   { @signals << RRR::Utils::Signals::QUIT   }
          Signal.trap(RRR::Utils::Signals::INT)    { @signals << RRR::Utils::Signals::QUIT   }
          Signal.trap(RRR::Utils::Signals::TERM)   { @signals << RRR::Utils::Signals::QUIT   }
          Signal.trap(RRR::Utils::Signals::RELOAD) { @signals << RRR::Utils::Signals::RELOAD }

          EM::add_periodic_timer( 0.5 ) do
            reload if @signals.delete( RRR::Utils::Signals::RELOAD )
            stop   if @signals.delete( RRR::Utils::Signals::QUIT )
          end
        end
      end
    end
  end
end
