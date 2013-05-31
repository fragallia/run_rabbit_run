module RRR
  module Loadbalancer
    class Worker 
      attr_accessor :name, :code, :worker, :queues

      def initialize name, queues
        @name, @queues = name, queues

        @timeout = Time.now.to_i + 30
        @stats   = RRR::Loadbalancer::WorkerStats.new
      end

      def reload
        stop
        # it will restore workers automatically
      end

      def stop
        @stopping = true

        @stats.number_of_consumers.times do | index |
          queues[:worker_stop].notify name: name
        end
      end

      def update_stats master_name, count
        @stats.update_number_of_consumers(master_name, count)
      end

      def check
        return unless worker.subscribed_queue_name

        @stopping = false if @stopping && @stats.number_of_consumers == 0

        worker.queues[worker.subscribed_queue_name].status do | number_of_messages, number_of_active_consumers |
          @stats.push(number_of_messages)

          if can_scale?
            puts "timeout: capacity:[#{worker.processes[:capacity]}] average:[#{@stats.average}] messages:[#{number_of_messages}] consumers:[#{@stats.number_of_consumers}]"

            scale :up   if has_to_scale_up?
            scale :down if has_to_scale_down?
          end
        end
      end

      def scale direction
        case direction.to_sym
        when :up
          number_of_processes_to_scale_up.times do | i | 
            queues[:worker_start].notify name: name, code: code
          end
        when :down
          queues[:worker_stop].notify name: name
        else
          return
        end

        @timeout = Time.now.to_i + 30
      end

      def code= value
        @code = value
      end

      def worker
        raise 'Set the code of the worker' unless code
        @worker ||= eval(code)
      end

      def has_to_scale_up?
        worker.processes[:capacity] < @stats.average &&
        @stats.number_of_consumers < worker.processes[:max]
      end

      def has_to_scale_down?
        (@stats.number_of_consumers - 1) * worker.processes[:capacity] > @stats.average &&
        @stats.number_of_consumers > worker.processes[:min]
      end

      def number_of_processes_to_scale_up
        if @stats.number_of_consumers < worker.processes[:desirable]
          return worker.processes[:desirable] - @stats.number_of_consumers
        end

        1 
      end

      def can_scale?
        @timeout < Time.now.to_i && !@stopping
      end

    end
  end
end
