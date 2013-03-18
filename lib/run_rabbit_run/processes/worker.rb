require 'run_rabbit_run/processes/base'

module RunRabbitRun
  module Processes
    class Worker < Base

      def start &block
        super &block
      end

    end
  end
end
