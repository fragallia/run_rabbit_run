require 'daemons'
require 'run_rabbit_run/processes/master'
require 'run_rabbit_run/amqp'

module RRR
  module Processes
    module MasterRunner
      extend self

      def start
        begin
          master = RRR::Processes::Master::Base.new

          Daemons.run_proc("ruby.rrr.master", RRR.config[:daemons]) do
            master.run
          end
        rescue => e
          RRR.logger.error e.message
        end
      end

      def stop
        Daemons.run_proc("ruby.rrr.master", RRR.config[:daemons].merge( ARGV: [ 'stop' ])) {}
      end
    end
  end
end
