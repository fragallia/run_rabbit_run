require 'run_rabbit_run/loadbalancer/worker'
require 'run_rabbit_run/loadbalancer/master'

module RRR
  module Loadbalancer
    class Base
      attr_accessor :workers

      def initialize queues
        @queues         = queues
        @masters        = {}
        @workers        = {}
      end

      def push worker_name, code
        @workers[worker_name] ||= RRR::Loadbalancer::Worker.new(worker_name, @queues)
        @workers[worker_name].code = code
        @workers[worker_name].reload
      end

      def check_status
        @workers.each { | name, worker | worker.check_for_status }
      end

      def scale
        @workers.each { | name, worker | worker.check_for_scale }

        capacity_available = @masters.size * 100
        capacity_used      = @masters.values.inject(0) { | sum, master | sum + master.capacity }

        if capacity_used + RRR.config[:reserved_capacity] > capacity_available
          #TODO server need to scale up
        elsif capacity_used + RRR.config[:reserved_capacity] > capacity_available - 100
          #TODO server need to scale down
          # if there is master free
          #   then shutdown the server
          # else
          #   move around the workers to free one master to scale down
        end 
      end

      def stats master_name, stats
        @masters[master_name] ||= RRR::Loadbalancer::Master.new(master_name)
        @masters[master_name].update stats

        update_number_of_consumers
      end

      def check_masters
        time_now = Time.now.to_i
        @masters.each do | name, master |
          if master.updated_at + 60 < time_now
            @masters.delete(name)
            update_number_of_consumers
          end
        end
      end

      def update_number_of_consumers
        @workers.each do | worker_name, worker |
          worker.number_of_consumers = number_of_consumers worker_name
        end
      end

      def number_of_consumers worker_name
        @masters.values.inject(0) { | sum, master | sum + master.number_of_consumers(worker_name) }
      end
    end
  end
end
