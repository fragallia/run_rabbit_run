require 'run_rabbit_run/loadbalancer/worker_stats'

module RRR
  module Loadbalancer
    class Worker 
      attr_accessor :name, :code, :worker, :queues

      def initialize name, queues
        @name, @queues = name, queues

        @timeout = 0
        @stats   = RRR::Loadbalancer::WorkerStats.new
      end

      def reload
        stop unless @stats.number_of_consumers == 0
        #workers with subscription will be run automatically
        unless worker.subscribable?
          worker.processes[:min].times do | index |
            queues['worker_start'].notify name: name, code: code, capacity: worker.processes[:load]
          end
        end
      end

      def stop
        @stopping = true

        @stats.number_of_consumers.times do | index |
          queues['worker_stop'].notify name: name
        end
      end

      def update_stats master_name, count
        @stats.update_number_of_consumers(master_name, count)

        @stopping = false if @stopping && @stats.number_of_consumers == 0
      end

      def check_status
        if worker.subscribable?
          worker.queues[worker.subscribed_to].status do | number_of_messages, number_of_active_consumers |
            @stats.push(number_of_messages)

            puts "average messages per worker:[#{@stats.average}] messages:[#{number_of_messages}] consumers:[#{@stats.number_of_consumers}]"
          end
        end
      end

      def scale direction
        case direction.to_sym
        when :up
          number_of_processes_to_scale_up.times do | i | 
            queues['worker_start'].notify name: name, code: code, capacity: worker.processes[:load]
          end
        when :down
          queues['worker_stop'].notify name: name
        else
          raise "Can't scale to #{direction}"
        end

        @timeout = Time.now.to_i + 30
      end

      def code= value
        @worker = eval(value)
        @code   = value
      end

      def worker
        raise 'Set the code of the worker' unless code
        @worker ||= eval(code)
      end

      def has_to_scale_up?
        @stats.number_of_consumers < worker.processes[:min] ||
        (
          worker.processes[:capacity] < @stats.average &&
          @stats.number_of_consumers < worker.processes[:max]
        )
      end

      def has_to_scale_down?
        (@stats.number_of_consumers - 1) * worker.processes[:capacity] > ( @stats.number_of_consumers * @stats.average) &&
        @stats.number_of_consumers > worker.processes[:min]
      end

      def number_of_processes_to_scale_up
        if @stats.number_of_consumers < worker.processes[:min]
          return worker.processes[:min] - @stats.number_of_consumers
        end

        if @stats.number_of_consumers < worker.processes[:desirable]
          return worker.processes[:desirable] - @stats.number_of_consumers
        end

        workers_needed = @stats.average/worker.processes[:capacity]
        if @stats.number_of_consumers + workers_needed > worker.processes[:max]
          return worker.processes[:max] - @stats.number_of_consumers
        end

        workers_needed
      end

      def can_scale?
        worker.subscribable? && @timeout < Time.now.to_i && !@stopping
      end

    end
  end
end
