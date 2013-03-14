module RunRabbitRun
  require 'run_rabbit_run/worker'

  class Workers
    attr_accessor :options
    def initialize(options = {})
      @options = options
      @workers = {}
    end

    def start
      options.each do | name, worker_options |
        worker = RunRabbitRun::Worker.new(name, worker_options)
        worker.run

        @workers[name] = worker
      end
    end

    def stop
      puts 'stop workers'
      # try to stop gracefully 
      @workers.each { | key, worker | worker.stop }
      
      # wait for 5 seconds for processes
      sleep 5

      self.kill
    end

    def kill
      @workers.each { | key, worker | worker.kill }
    end

    def reload(options)
      @options = options
      #TODO run new workers
      #TODO stop old workers
    end
  end
end
