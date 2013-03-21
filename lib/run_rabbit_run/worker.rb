require 'run_rabbit_run/processes/signals'

module RunRabbitRun
  class Worker
    attr_accessor :name, :guid, :pid, :status
    def initialize(name, guid)
      @name, @guid, @pid = name, guid, nil

      @status = :unknown
    end

    def run
      #TODO get path for bundle
      success = system("RAKE_ENV=#{RunRabbitRun.config[:environment]} bundle exec rake rrr:worker:new[#{@name},#{@guid}]")
    end

    def kill
      RunRabbitRun::Processes::Signals.kill_signal(@guid, @pid)
    end

    def stop
      RunRabbitRun::Processes::Signals.stop_signal(@guid, @pid)
    end

    def reload
      RunRabbitRun::Processes::Signals.reload_signal(@guid, @pid)
    end

    def running?
      RunRabbitRun::Processes::Signals.running? @pid
    end
  end
end
