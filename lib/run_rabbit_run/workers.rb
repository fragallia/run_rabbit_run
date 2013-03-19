module RunRabbitRun
  require 'run_rabbit_run/worker'

  class Workers
    def initialize
      @workers = {}
    end

    def check
      @workers.each do | name, workers |
        options = RunRabbitRun.config[:workers][name]

        workers.each do | guid, worker |
          worker.run options unless worker.running?
        end
        diff = workers.size - RunRabbitRun.config[:workers][name][:processes]
        diff.times{ run_new_worker name }
      end
    end

    def start
      RunRabbitRun.config[:run].each do | name |
        RunRabbitRun.config[:workers][name][:processes].times do | n |
          run_new_worker name
        end
      end
    end

    def stop
      RunRabbitRun.logger.info 'stop workers'
      # try to stop gracefully 
      @workers.each { | name, workers | workers.each { | guid, worker | worker.stop } }
     
      sleep 1 

      @workers.each do | name, workers |
        workers.each do | guid, worker | 
          if worker.running?
            sleep 4
            kill # kill workers which are still running
            return
          end
        end
      end
    end

    def kill
      @workers.each { | name, workers | workers.each { | guid, worker | worker.kill if worker.running? } }
    end

    def reload
      RunRabbitRun.load_config( RunRabbitRun.config[:application_path] )
      #TODO run new workers
      #TODO stop old workers
    end

  private

    def run_new_worker name
      guid    = generate_guid(name)
      options = RunRabbitRun.config[:workers][name]

      worker = RunRabbitRun::Worker.new(guid)
      worker.run options

      @workers[name] ||= {}
      @workers[name][guid] = worker
    end

    def generate_guid name
      "#{name}-#{((@workers[name] and @workers[name].keys.size) || 0) + 1}"
    end

  end
end
