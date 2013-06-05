require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/logger'
require 'run_rabbit_run/utils/signals'
require 'run_rabbit_run/utils/system'
require 'run_rabbit_run/processes/master/workers'

module RRR
  module Processes
    module Master

      class Base
        # unique name for the master process
        attr_accessor :name

        # keeps statuses of workers
        attr_accessor :workers

        def initialize
          @name = "master.#{RRR::Utils::System.ip_address}"
          @workers = RRR::Processes::Master::Workers.new(@name)
          @stopping = false
        end

        def run options = {}
          EM.run do
            RRR::Amqp.channel.prefetch 1
            RRR.logger = RRR::Amqp::Logger.new

            listen_to_signals

            queues[:master].subscribe &method(:handle_worker_message)
            queues[:worker_start].subscribe ack: true, &method(:handle_worker_start_message)
            queues[:worker_stop].subscribe ack: true, &method(:handle_worker_stop_message)

            EM.add_periodic_timer(30) do
              send_stats_to_loadbalancer
            end
          end
        end

        def stop
          @stopping = true
          queues[:worker_start].unsubscribe

          @workers.stop_all

          # wait to stop all workers
          EM.add_periodic_timer(0.1) do
            RRR::Amqp.stop if @workers.running_workers.size == 0
          end
          # kill all running workers and exit after 30 secs
          EM.add_timer(30) do
            @workers.kill_all
            RRR::Amqp.stop
          end
        end

      private

        def queues
          @queues ||= {
            worker_start: RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.start", durable: true),
            worker_stop:  RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.worker.stop", durable: true),
            loadbalancer: RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.loadbalancer", durable: true),
            master:       RRR::Amqp::Queue.new("#{RRR.config[:env]}.system.#{@name}", auto_delete: true),
          }
        end

        def handle_worker_stop_message headers, payload
          if @workers.stop payload['name']
            headers.ack
          else
            if headers.delivery_tag > 1000
              RRR.logger.error "Worker stop failed [#{headers.headers['name']}][#{headers.headers['ip']}][#{headers.headers['pid']}] with [#{payload.inspect}]"
              headers.reject
            else
              headers.reject requeue: true
            end
          end
        end

        def handle_worker_start_message headers, payload
          if @stopping
            headers.reject requeue: true
          else
            begin
              raise "No worker name given #{headers.headers.inspect}, #{payload.inspect}" unless payload['name']
              raise "No capacity given #{headers.headers.inspect}, #{payload.inspect}"    unless payload['capacity']
              raise "No code given #{headers.headers.inspect}, #{payload.inspect}"        unless payload['code']

              if @workers.create(payload['name'], payload['code'], payload['capacity'])
                headers.ack
              else
                queues[:worker_start].unsubscribe nowait: false do
                  headers.reject requeue: true
                  RRR.logger.error "Worker can\'t be run, capacity exceeded #{payload.inspect}"
                end
              end
            rescue => e
              RRR.logger.error "#{e.message},\n#{e.backtrace.join("\n")}"
              headers.reject
            end
          end
        end

        def handle_worker_message headers, payload
          RRR.logger.info "master got message from [#{headers.headers['name']}][#{headers.headers['ip']}][#{headers.headers['pid']}] with [#{payload.inspect}]"

          begin
            case payload['message'].to_sym
            when :started
              @workers.started headers.headers['worker_id'], headers.headers['pid'], headers.headers['created_at']
            when :finished
              @workers.finished headers.headers['worker_id']
              begin
                queues[:worker_start].subscribe ack: true, &method(:handle_worker_start_message)
              rescue
                # if already subscribed
              end
            end

            send_stats_to_loadbalancer
          rescue => e
            RRR.logger.error "#{e.message},\n#{e.backtrace.join("\n")}"
          end
        end

        def send_stats_to_loadbalancer
          queues[:loadbalancer].notify({ action: :stats, stats: @workers.stats, name: name })
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
