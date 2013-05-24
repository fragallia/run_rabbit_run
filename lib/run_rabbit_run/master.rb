require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/logger'
require 'run_rabbit_run/utils/signals'

module RRR
  module Master

    class Base
      # unique name for the master process
      attr_accessor :name

      # name of the master queue, local workers reports to this queue
      attr_accessor :queue_name

      # master capacity, that is how many workers master can run
      attr_accessor :capacity

      # hash with currently running workers
      attr_accessor :running_workers

      def initialize
        @capacity = 10
        @name = "master.#{SecureRandom.uuid.gsub(/[^A-za-z0-9]/,"")}"
        @queue_name = "#{RRR.config[:env]}.system.#{@name}"
        @running_workers = {}
      end

      def run options = {}
        EM.run do
          RRR::Amqp.channel.prefetch 1
          RRR.logger = RRR::Amqp::Logger.new

          listen_to_signals
          listen_to_workers
          listen_to_worker_new
          listen_to_worker_destroy
        end
      end

      def stop
        RRR::Amqp.stop
      end

    private

      def listen_to_worker_destroy
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.destroy", durable: true)
        queue.subscribe( ack: true ) do | headers, payload |
          if @running_workers[payload['name']] && !@running_workers[payload['name']].empty?
            RRR::WorkerRunner.stop(@running_workers[payload['name']].shift)

            headers.ack
          else
            headers.reject
          end

        end
      end

      def listen_to_worker_new
        queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.new", durable: true)
        queue.subscribe( ack: true ) do | headers, payload |
          if @capacity > 0
            RRR::WorkerRunner.build(name, payload['code'])

            headers.ack
          else
            headers.reject
            queue.unsubscribe
          end

        end
      end

      def listen_to_workers
        queue = RRR::Amqp::Queue.new(@queue_name, auto_delete: true)
        queue.subscribe do | headers, payload |
          RRR.logger.info "master got message from [#{headers.headers['name']}][#{headers.headers['host']}][#{headers.headers['pid']}] with [#{payload.inspect}]"

          case payload['message'].to_sym
          when :started
            if headers.headers['name'] && headers.headers['pid']
              @running_workers[headers.headers['name']] ||= []
              @running_workers[headers.headers['name']] << headers.headers['pid']
            end
          when :finished
            if headers.headers['name'] && headers.headers['pid']
              @running_workers[headers.headers['name']].delete(headers.headers['pid']) if @running_workers[headers.headers['name']]
            end
          end
        end
      end

      def listen_to_signals
        signals    = []

        Signal.trap(RRR::Utils::Signals::QUIT)   { signals << RRR::Utils::Signals::QUIT   }
        Signal.trap(RRR::Utils::Signals::INT)    { signals << RRR::Utils::Signals::QUIT   }
        Signal.trap(RRR::Utils::Signals::TERM)   { signals << RRR::Utils::Signals::QUIT   }

        EM::add_periodic_timer( 0.5 ) do
          stop if signals.delete( RRR::Utils::Signals::QUIT )
        end
      end
    end
  end
end
