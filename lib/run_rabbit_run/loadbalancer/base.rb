module RRR
  module Loadbalancer
    class Base
      attr_accessor :workers

      def initialize
        @workers        = {}
        @master_updates = {}
      end

      def push worker_name, code
        @workers[worker_name] ||= RRR::Loadbalancer::Worker.new
        @workers[worker_name] = code
        @workers[worker_name].reload
      end

      def check
        @workers.each { | name, worker | worker.check }
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
          if time < time_now
            @master_updates.delete(master_name)
            @workers.each { | worker_name, worker | worker.update_stats(master_name, 0) }
          end
        end
      end
    end
  end
end
