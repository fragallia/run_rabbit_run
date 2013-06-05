require 'run_rabbit_run/utils/signals'

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
          running_workers.each do | worker |
            RRR::Processes::WorkerRunner.stop(worker[:pid]) if worker[:status] == :started
          end
        end

        def stop name
          worker = running_workers.find { | worker | worker[:name] == name && worker[:status] == :started }

          if worker
            worker[:status]     = :removing
            worker[:removed_at] = Time.now.to_i
            RRR::Processes::WorkerRunner.stop(worker[:pid])
          
            worker
          end
        end

        def kill_all
          running_workers.each do | worker |
            RRR::Processes::WorkerRunner.kill(worker[:pid])
          end
        end

        def create name, code, capacity
          if @capacity - capacity >= 0
            worker_id = (@workers.keys.max || 0) + 1

            RRR::Processes::WorkerRunner.build(@master_name, worker_id, code)

            @workers[worker_id] = {
              id:         worker_id,
              name:       name,
              status:     :create,
              capacity:   capacity,
              created_at: Time.now.to_i,
            }

            @capacity -= capacity
   
            worker_id
          end
        end

        def started worker_id, pid, created_at
          worker = @workers[worker_id.to_i]
          if worker
            worker[:status]     = :started
            worker[:pid]        = pid
            worker[:started_at] = created_at
          else
            raise 'Worker not exists'
          end
        end

        def finished worker_id
          worker = @workers.delete(worker_id.to_i)
          if worker
            @capacity += worker[:capacity]
          else
            raise 'Worker not exists'
          end
        end

        def running_workers
          @workers.values.select { | worker | !worker[:pid].nil? }
        end

        def stats
          @workers
        end

      end
    end
  end
end
