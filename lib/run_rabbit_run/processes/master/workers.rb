require 'run_rabbit_run/utils/signals'
require 'run_rabbit_run/processes/master/worker'

module RRR
  module Processes
    module Master
      class Workers
        attr_accessor :capacity

        def initialize master_name
          @capacity    = 100
          @workers     = {}
          @master_name = master_name
        end

        def stop_all
          running_workers.each(&:stop)
        end

        def stop name
          worker = running_workers.find do | worker |
            worker.name == name && worker.status == RRR::Processes::Master::Worker::STATUS_STARTED
          end
          worker.stop if worker
          
          worker
        end

        def kill_all
          running_workers.each(&:kill)
        end

        def create name, code, capacity
          if @capacity - capacity >= 0
            worker_id = (@workers.keys.max || 0) + 1

            @workers[worker_id] = RRR::Processes::Master::Worker.new({
              id:          worker_id,
              name:        name,
              master_name: @master_name,
              capacity:    capacity,
              code:        code
            })

            @workers[worker_id].start

            @capacity -= capacity
   
            worker_id
          end
        end

        def started worker_id, pid, created_at
          worker = @workers[worker_id.to_i]
          if worker
            worker.started pid, created_at
          else
            raise 'Worker not exists'
          end
        end

        def finished worker_id
          worker = @workers.delete(worker_id.to_i)
          if worker
            @capacity += worker.capacity
          else
            raise 'Worker not exists'
          end
        end

        def running_workers
          @workers.values.select { | worker | worker.running? }
        end

        def stats
          @workers
        end

      end
    end
  end
end
