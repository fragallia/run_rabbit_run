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
      if RunRabbitRun.config[:run].include? name.to_sym
        run_new_worker name
      else
        if RunRabbitRun.config[:workers].keys.include? name.to_sym
          RunRabbitRun.logger.error "[#{name}] worker is not included into [#{RunRabbitRun.config[:environment]}] profile"
        else
          RunRabbitRun.logger.error "No configuration found for [#{name}] worker"
        end
      end
    end

    def remove name
      guid = @workers[name.to_sym].keys.sort.first
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

      @workers = {}
    end

    def kill
      @workers.each { | name, workers | workers.each { | guid, worker | worker.kill if worker.running? } }

      @workers = {}
    end

    def reload
      # reload the config file
      RunRabbitRun.load_config( RunRabbitRun.config[:application_path] )

      self.stop 
      self.start
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
      last_guid = @workers[name].keys.sort.last if @workers[name]

      index = (last_guid ? last_guid.split('-').last.to_i : 0) + 1

      "#{name}-#{index}"
    end

  end
end
