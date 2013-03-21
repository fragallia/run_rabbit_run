module RunRabbitRun
  module Processes
    module Signals
      extend self

      def running? pid
        return false unless pid

        begin
          Process.getpgid(pid.to_i )

          return true
        rescue Errno::ESRCH
        rescue Exception => e
          RunRabbitRun.logger.error "#{e}, #{e.backtrace.join("\n")}"
        end

        return false
      end

      def kill_signal name, pid
        send_signal name, pid, RunRabbitRun::SIGNAL_KILL
      end

      def stop_signal name, pid
        send_signal name, pid, RunRabbitRun::SIGNAL_EXIT
      end

      def reload_signal name, pid
        send_signal name, pid, RunRabbitRun::SIGNAL_RELOAD
      end

    private

      def send_signal name, pid, signal
        if running? pid
          RunRabbitRun.logger.info "[#{name}] send #{signal_name(signal)} signal to process"
          Process.kill(signal, pid)
        else
          RunRabbitRun.logger.debug "[#{name}] is not running"
        end
      end

      def signal_name code
        case code
        when 'QUIT'
          'exit'
        when 'USR1'
          'reload'
        when 'KILL'
          'kill'
        end
      end
    end
  end
end
