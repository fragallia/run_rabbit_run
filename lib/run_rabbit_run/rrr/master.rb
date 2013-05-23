require 'run_rabbit_run/rrr/amqp'
require 'run_rabbit_run/rrr/amqp/logger'

module RRR
  module Master

#TODO's
# subscribe to the queue
#   process messages from worker
# subscribe to system.env.worker.new
#   take worker code
#   create gemfile
#   create worker file
#   run bundle install with --gemfile
#   run worker with --gemfile

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
        @queue_name = "#{RunRabbitRun.config[:environment]}.system.#{@name}"
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
        queue = RRR::Amqp::Queue.new("#{RunRabbitRun.config[:environment]}.system.worker.destroy", durable: true)
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
        queue = RRR::Amqp::Queue.new("#{RunRabbitRun.config[:environment]}.system.worker.new", durable: true)
        queue.subscribe( ack: true ) do | headers, payload |
          if @capacity > 0
            RRR::WorkerRunner.build(payload['code'])

            headers.ack
          else
            headers.reject
            queue.unsubscribe
          end

        end
      end

      def listen_to_workers
        queue = RRR::Amqp::Queue.new(@queue_name, auto_delete: true, exclusive: true)
        queue.subscribe do | headers, payload |
            case payload['message'].to_sym
            when :started
              if headers.headers[:name] && headers.headers[:pid]
                @running_workers[headers.headers[:name]] ||= []
                @running_workers[headers.headers[:name]] << headers.headers[:pid]
              end
            when :finished
              if headers.headers[:name] && headers.headers[:pid]
                @running_workers[headers.headers[:name]].delete(headers.headers[:pid]) if @running_workers[headers.headers[:name]]
              end
            end
        end
      end

      def listen_to_signals
        signals    = []

        Signal.trap(RunRabbitRun::SIGNAL_EXIT)   { signals << RunRabbitRun::SIGNAL_EXIT   }
        Signal.trap(RunRabbitRun::SIGNAL_INT)    { signals << RunRabbitRun::SIGNAL_EXIT   }
        Signal.trap(RunRabbitRun::SIGNAL_TERM)   { signals << RunRabbitRun::SIGNAL_EXIT   }

        EM::add_periodic_timer( 0.5 ) do
          stop if signals.delete( RunRabbitRun::SIGNAL_EXIT )
        end
      end
    end
  end
end