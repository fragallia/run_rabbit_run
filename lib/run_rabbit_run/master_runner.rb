require 'daemons'
require 'run_rabbit_run/master'
require 'run_rabbit_run/amqp'

module RRR
  module MasterRunner
    extend self

    def start
      begin
        master = RRR::Master::Base.new

        options = {
          ontop: ( RRR.config[:env] == 'test' ),
          log_output: true,
          dir:        RRR.config[:pid],
          log_dir:    RRR.config[:log],
          ARGV:       [ 'start' ]
        }

        Daemons.run_proc("ruby.rrr.master", options) do
          master.run
        end
      rescue => e
        RRR.logger.error e.message
      end
    end

    def stop
      options = @daemons_default_options.merge({ ARGV: [ 'stop' ] })
      Daemons.run_proc("ruby.rrr.master", options) {}
    end
  end
end
