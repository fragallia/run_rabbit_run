module RunRabbitRun
  require 'run_rabbit_run/worker'

  class Workers
    def initialize
      @workers = {}
    end

    def worker(guid)
      @workers.each do | name, workers |
        workers.each do | current_guid, worker |
          return worker if current_guid == guid
        end
      end

      nil
    end

    def check
      @workers.each do | name, workers |
        workers.each do | guid, worker |
          worker.run unless worker.running?
        end
        diff = RunRabbitRun.config[:workers][name][:processes] - workers.size
        diff.times{ run_new_worker name } if diff > 0
      end
    end

    def add name
      run_new_worker name
    end

    def remove name
      guid = @workers[name.to_sym].keys.sort.last
      worker = @workers[name.to_sym][guid]

      worker.stop

      sleep 1

      if worker.running?
        sleep 4
        worker.kill if worker.running?
      end

      @workers[name.to_sym].delete(guid)
    end

    def start
      RunRabbitRun.config[:run].each do | name |
        RunRabbitRun.config[:workers][name][:processes].times do | n |
          run_new_worker name
        end
      end
    end

    def stop
      # try to stop gracefully 
      @workers.each { | name, workers | workers.each { | guid, worker | worker.stop } }
     
      sleep 1 

      @workers.each do | name, workers |
        workers.each do | guid, worker | 
          if worker.running?
            sleep 4
            self.kill # kill workers which are still running
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
      name   = name.to_sym
      guid   = generate_guid(name)
      worker = RunRabbitRun::Worker.new(name, guid)

      @workers[name] ||= {}
      @workers[name][guid] = worker

      worker.run
    end

    def generate_guid name
      "#{name}-#{((@workers[name] and @workers[name].keys.size) || 0) + 1}"
    end

  end
end
