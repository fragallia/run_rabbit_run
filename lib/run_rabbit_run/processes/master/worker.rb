require 'run_rabbit_run/utils/signals'

module RRR
  module Processes
    module Master
      class Worker
        # worker id
        attr_accessor :id

        # worker name
        attr_accessor :name

        # worker status
        attr_accessor :status

        # worker pid 
        attr_accessor :pid

        # worker master name
        attr_accessor :master_name

        # worker capacity
        attr_accessor :capacity

        # worker code
        attr_accessor :code

        # date when master sent start to worker
        attr_accessor :created_at

        # date when master sent stop to worker
        attr_accessor :stopped_at

        # date when worker started
        attr_accessor :started_at

        STATUS_NEW      = :new
        STATUS_STARTED  = :started
        STATUS_CREATE   = :create
        STATUS_STOPPING = :stopping

        def initialize attributes = {}
          @status = STATUS_NEW
          attributes.each { | key, value | self.send("#{key}=", value) }
        end

        def start
          RRR::Processes::WorkerRunner.build(master_name, id, code)

          @created_at = Time.now.to_i
          @status     = STATUS_CREATE
        end

        def started pid, started_at
          @status     = STATUS_STARTED
          @pid        = pid
          @started_at = started_at
        end

        def stop
          if @status == STATUS_STARTED
            @status     = STATUS_STOPPING
            @stopped_at = Time.now.to_i

            RRR::Processes::WorkerRunner.stop(@pid)
          end
        end

        def kill
          RRR::Processes::WorkerRunner.kill(@pid) if @pid
        end

        def running?
          !@pid.nil?
        end

        def to_json *a
          {
            id:          @id,
            name:        @name, 
            status:      @status, 
            pid:         @pid,
            master_name: @master_name,
            capacity:    @capacity,
            created_at:  @created_at, 
            stopped_at:  @stopped_at, 
            started_at:  @started_at, 
          }.to_json(*a)
        end
      end
    end
  end
end
