require 'run_rabbit_run/loadbalancer/worker_stats'

module RRR
  module Loadbalancer
    class Worker 
      attr_accessor :name, :code, :worker, :queues, :number_of_consumers

      def initialize name, queues
        @name, @queues = name, queues

        @stopping = false
        @number_of_consumers = 0
        @consumers_requested = 0
        @timeout = 0
        @stats   = RRR::Loadbalancer::WorkerStats.new
      end

      def number_of_consumers= value
        @stopping = false if value == 0

        @number_of_consumers = value
      end

      def reload
        stop
        start
      end

      def start
        #workers with subscription will be run automatically
        scale :up, worker.processes[:min] unless worker.subscribable?
      end

      def stop
        if number_of_consumers > 0
          @stopping = true
          scale :down, number_of_consumers
        end
      end

      def check_for_status
        if worker.subscribable?
          worker.queues[worker.subscribed_to].status do | number_of_messages, number_of_active_consumers |
            @stats.push(number_of_messages)

            puts "average messages:[#{@stats.average/(number_of_consumers > 0 ? number_of_consumers : 1)}] messages:[#{number_of_messages}] consumers:[#{number_of_consumers}]"
          end
        end
      end

      def check_for_scale
        if can_scale?
          if scale_up?
            count = number_of_consumers + number_of_processes_to_scale_up - @consumers_requested

            scale :up, count if count > 0
          elsif scale_down?
            scale :down      if number_of_consumers <= @consumers_requested
          end
        end
      end

      def scale direction, count = 1
        case direction.to_sym
        when :up
          count.times do | i | 
            queues['worker_start'].notify name: name, code: code, capacity: worker.settings[:capacity]

            @consumers_requested += 1
          end
        when :down
          count.times do | i | 
            queues['worker_stop'].notify name: name

            @consumers_requested -= 1
          end
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

      def scale_up?
        number_of_consumers < worker.processes[:min] ||
        (
          worker.settings[:queue_size]*number_of_consumers < @stats.average &&
          number_of_consumers < worker.processes[:max]
        )
      end

      def scale_down?
        (number_of_consumers - 1) * worker.settings[:queue_size] > @stats.average &&
        number_of_consumers > worker.processes[:min]
      end

      def number_of_processes_to_scale_up
        if number_of_consumers < worker.processes[:min]
          return worker.processes[:min] - number_of_consumers
        end

        if number_of_consumers < worker.processes[:desirable]
          return worker.processes[:desirable] - number_of_consumers
        end

        workers_needed = @stats.average/worker.settings[:queue_size] - number_of_consumers
        if number_of_consumers + workers_needed > worker.processes[:max]
          return worker.processes[:max] - number_of_consumers
        end

        workers_needed
      end

      def can_scale?
        worker.subscribable? && @timeout < Time.now.to_i && !@stopping
      end

    end
  end
end
