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
          RRR.logger.error "#{e.message},\n#{e.backtrace.join("\n")}"
        end

        return false
      end

      def kill_signal pid
        send_signal pid, RRR::Utils::Signals::KILL
      end

      def stop_signal pid
        send_signal pid, RRR::Utils::Signals::QUIT
      end

      def reload_signal pid
        send_signal pid, RRR::Utils::Signals::RELOAD
      end

    private

      def send_signal pid, signal
        Process.kill(signal, pid) if running? pid
      end
    end
  end
end
