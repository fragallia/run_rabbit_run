require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/logger'
require 'run_rabbit_run/utils/signals'
require 'run_rabbit_run/utils/system'

module RRR
  module Processes
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
          @name = "master.#{RRR::Utils::System.ip_address}"
          @queue_name = "#{RRR.config[:env]}.system.#{@name}"
          @running_workers = {}
        end

        def run options = {}
          EM.run do
            RRR::Amqp.channel.prefetch 1
            RRR.logger = RRR::Amqp::Logger.new

            listen_to_signals
            listen_to_workers
            listen_to_worker_start
            listen_to_worker_stop

            EM.add_periodic_timer(30) do
              send_stats_to_loadbalancer
            end
          end
        end

        def stop
          queue = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.start", durable: true)
          queue.unsubscribe

          @running_workers.each do | name, pids |
            pids.each do | pid |
              RRR::Processes::WorkerRunner.stop(pid)
            end
          end
          # wait to stop all workers
          EM.add_periodic_timer(0.1) do
            workers_count =  @running_workers.values.inject(0) { |sum, x | sum + x.count }
            RRR::Amqp.stop if workers_count == 0
          end
          # kill all running workers and exit after 30 secs
          EM.add_timer(30) do
            @running_workers.each do | name, pids |
              pids.each do | pid |
                RRR::Processes::WorkerRunner.kill(pid)
              end
            end
            RRR::Amqp.stop
          end
        end

      private

        def listen_to_worker_stop
          queue         = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.stop", durable: true)
          queue.subscribe( ack: true ) do | headers, payload |
            if @running_workers[payload['name']] && !@running_workers[payload['name']].empty?
              RRR::Processes::WorkerRunner.stop(@running_workers[payload['name']].shift)

              headers.ack
            else
              if headers.delivery_tag > 100
                RRR.logger.error "Worker stop failed [#{headers.headers['name']}][#{headers.headers['ip']}][#{headers.headers['pid']}] with [#{payload.inspect}]"
                headers.reject
              else
                headers.reject requeue: true
              end
            end

          end
        end

        def listen_to_worker_start
          queue         = RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.start", durable: true)
          queue.subscribe( ack: true ) do | headers, payload |
            if @capacity > 0
              RRR::Processes::WorkerRunner.build(name, payload['code'])

              headers.ack
            else
              headers.reject requeue: true
              queue.unsubscribe
            end

          end
        end

        def listen_to_workers
          queue = RRR::Amqp::Queue.new(@queue_name, auto_delete: true)
          queue.subscribe do | headers, payload |
            RRR.logger.info "master got message from [#{headers.headers['name']}][#{headers.headers['ip']}][#{headers.headers['pid']}] with [#{payload.inspect}]"

            case payload['message'].to_sym
            when :started
              if headers.headers['name'] && headers.headers['pid']
                @running_workers[headers.headers['name']] ||= []
                @running_workers[headers.headers['name']] << headers.headers['pid']

                send_stats_to_loadbalancer
              end
            when :finished
              if headers.headers['name'] && headers.headers['pid']
                @running_workers[headers.headers['name']].delete(headers.headers['pid']) if @running_workers[headers.headers['name']]

                send_stats_to_loadbalancer
              end
            end
          end
        end

        def send_stats_to_loadbalancer
          RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.loadbalancer", durable: true).notify({
            action: :stats,
            stats: @running_workers.inject({}) { | res, item |  res[item[0]] = item[1].count; res },
            name: name
          })
        end

        def listen_to_signals
          @signals    = []

          Signal.trap(RRR::Utils::Signals::QUIT)   { @signals << RRR::Utils::Signals::QUIT   }
          Signal.trap(RRR::Utils::Signals::INT)    { @signals << RRR::Utils::Signals::QUIT   }
          Signal.trap(RRR::Utils::Signals::TERM)   { @signals << RRR::Utils::Signals::QUIT   }

          EM::add_periodic_timer( 0.5 ) do
            stop if @signals.delete( RRR::Utils::Signals::QUIT )
          end
        end
      end
    end
  end
end
