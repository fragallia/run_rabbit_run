module RunRabbitRun
  require 'run_rabbit_run/worker'

  class Workers
    def initialize
      @workers = {}
    end

    def status worker, status
      case status
      when :process_quit
        @workers.delete(worker)
      when :process_started
        @workers[worker].status = :ready
      when :message_received
        @workers[worker].status = :busy
      when :message_processed
        @workers[worker].status = :ready
      else
        @workers[worker].status = :unknown
      end
    end

    def start
      RunRabbitRun.config[:run].each do | name |
        worker = RunRabbitRun::Worker.new(name)
        worker.run

        @workers[name] = worker
      end
    end

    def stop
      RunRabbitRun.logger.info 'stop workers'
      # try to stop gracefully 
      @workers.each { | key, worker | worker.stop }
     
      sleep 1 

      if @workers.find { | key, worker | worker.running? }
        sleep 4
        # kill workers which are still running
        @workers.each { | key, worker | worker.kill if worker.running? }
      end
    end

    def kill
      @workers.each { | key, worker | worker.kill }
    end

    def reload
      RunRabbitRun.load_config( RunRabbitRun.config[:application_path] )
      #TODO run new workers
      #TODO stop old workers
    end

  end
end
