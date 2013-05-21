require 'daemons'
require 'run_rabbit_run/rrr/worker'
require 'run_rabbit_run/rrr/amqp'
require 'run_rabbit_run/rrr/amqp/system'

module RRR
  module WorkerRunner
    extend self

    #TODO move to the config
    @daemons_default_options =  {
      multiple:   true,
      log_output: true,
      dir:        File.expand_path("./tmp/pids", '.'),
      log_dir:    File.expand_path("./log", '.'),
      ARGV:       [ 'start' ]
    }

    def start master_name, file_path
      begin
        worker_code = File.read(file_path)
        @worker = eval(worker_code)

        # sets reporting to the master
        report_to_master master_name

        options = @daemons_default_options.merge({
          ontop: ( RunRabbitRun.config[:environment] == 'test' )
        })

        Daemons.run_proc("ruby.rrr.#{@worker.name}", options) do
          @worker.run
        end
      rescue => e
        #TODO report error
        puts e
      end
    end

  private

    def report_to_master name
      @master = RRR::Amqp::System.new name, @worker.name
      @worker.on_start { @master.notify :started }
      @worker.on_exit  { @master.notify :finished }
    end
  end
end
