module RunRabbitRun
  class Worker
    attr_accessor :name, :options, :pid
    def initialize(name, options)
      @name, @options = name, options
    end

    def display_name
      @options[:name] || @name
    end

    def run

      raise "The worker <#{display_name}> is already running" if self.running?

      puts "[INFO] [RunRabbitRun] worker <#{display_name}> starting"

      @pid = fork do
        $0 = "[ruby] [RunRabbitRun] [#{display_name}] worker process"

        load options[:path]

        puts "[ruby] [RunRabbitRun] [#{display_name}] worker process finished"
      end

      Process.detach(@pid)
    end

    def stop
      if running?
        puts "[INFO] send exit signal to worker <#{display_name}> process"
        Process.kill(RunRabbitRun::SIGNAL_EXIT, pid)

        Pid.remove
      else
        puts "[ERROR] no process running"
      end
    end

    def kill
      if self.running?
        puts "[INFO] kill worker <#{display_name}> process"
        Process.kill(RunRabbitRun::SIGNAL_KILL, pid)

        Pid.remove
      else
        puts "[ERROR] no process running"
      end
    end

    def running?
      return false unless pid

      begin
        Process.getpgid(pid.to_i )

        return true
      rescue Errno::ESRCH
      rescue Exception => e
        puts "[ERROR] #{e}, #{e.backtrace.join("\n")}"
      end

      return false
    end
  end
end
