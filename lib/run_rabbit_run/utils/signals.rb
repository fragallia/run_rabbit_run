module RRR
  module Utils
    module Signals
      extend self

      QUIT   = 'QUIT'
      INT    = 'INT'
      TERM   = 'TERM'
      RELOAD = 'USR1'
      KILL   = 'KILL'

      def running? pid
        return false unless pid

        begin
          Process.getpgid(pid.to_i )

          return true
        rescue Errno::ESRCH
        rescue Exception => e
          RRR.logger.error "#{e}, #{e.backtrace.join("\n")}"
        end

        return false
      end

      def kill_signal name, pid
        send_signal name, pid, RRR::Utils::Signals::KILL
      end

      def stop_signal name, pid
        send_signal name, pid, RRR::Utils::Signals::QUIT
      end

      def reload_signal name, pid
        send_signal name, pid, RRR::Utils::Signals::RELOAD
      end

    private

      def send_signal name, pid, signal
        if running? pid
          RRR.logger.info "[#{name}] send #{signal_name(signal)} signal to process"
          Process.kill(signal, pid)
        else
          RRR.logger.debug "[#{name}] is not running"
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
