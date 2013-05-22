require 'daemons'
require 'run_rabbit_run/rrr/master'
require 'run_rabbit_run/rrr/amqp'

module RRR
  module MasterRunner
    extend self

    #TODO move to the config
    @daemons_default_options =  {
      log_output: true,
      dir:        File.expand_path("./tmp/pids", '.'),
      log_dir:    File.expand_path("./log", '.'),
      ARGV:       [ 'start' ]
    }

    def start
      begin
        master = RRR::Master::Base.new

        options = @daemons_default_options.merge({
          ontop: ( RunRabbitRun.config[:environment] == 'test' )
        })

        Daemons.run_proc("ruby.rrr.master", options) do
          master.run
        end
      rescue => e
        #TODO report error
        puts e
      end
    end

    def stop
        options = @daemons_default_options.merge({
          ARGV: [ 'stop' ]
        })
      Daemons.run_proc("ruby.rrr.master", options) {}
    end
  end
end
