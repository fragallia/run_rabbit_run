require 'run_rabbit_run/loadbalancer/worker'

module RRR
  module Loadbalancer
    class Base
      attr_accessor :workers

      def initialize queues
        @workers        = {}
        @master_updates = {}
        @queues         = queues
      end

      def push worker_name, code
        @workers[worker_name] ||= RRR::Loadbalancer::Worker.new(worker_name, @queues)
        @workers[worker_name].code = code
        @workers[worker_name].reload
      end

      def check_status
        @workers.each { | name, worker | worker.check_status }
      end

      def scale
        @workers.each do | name, worker |
          if worker.can_scale?
            if worker.has_to_scale_up?
              worker.scale :up
            elsif worker.has_to_scale_down?
              worker.scale :down
            end
          end
        end
      end

      def stats master_name, stats
        stats.each do | worker_name, count |
          next unless @workers[worker_name]
          @workers[worker_name].update_stats(master_name, count)
        end

        @master_updates[master_name] = Time.now.to_i
      end

      def check_masters
        time_now = Time.now.to_i
        @master_updates.each do | master_name, time |
          if time + 60 < time_now
            @master_updates.delete(master_name)
            @workers.each { | worker_name, worker | worker.update_stats(master_name, 0) }
          end
        end
      end
    end
  end
end
