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

    @gemfile_default_gems = {
      run_rabbit_run: []
    }

    def build worker_code
      begin
        begin
          worker = eval(worker_code)
        rescue => e
          raise 'worker evaluates with exceptions'
        end

        worker_dir = "#{RunRabbitRun.config[:application_path]}/tmp/workers/#{RunRabbitRun.config[:environment]}/#{worker.name}"
        FileUtils.mkdir_p(worker_dir) unless File.exists?(worker_dir)

        create_gemfile worker, "#{worker_dir}/Gemfile"

        File.open("#{worker_dir}/worker.rb", 'w') { |f| f.write(worker_code) }
        File.delete("#{worker_dir}/Gemfile.lock") if File.exists?("#{worker_dir}/Gemfile.lock")

        output = ""
        Bundler.with_clean_env do
          output = `cd #{worker_dir}; bundle install --gemfile #{worker_dir}/Gemfile`
        end

        raise "bundle install failed: #{output}" unless File.exists?("#{worker_dir}/Gemfile.lock")

        Bundler.with_clean_env do
          output = `cd #{RunRabbitRun.config[:application_path]}; pwd; BUNDLE_GEMFILE=#{worker_dir}/Gemfile bundle exec rake rrr:worker:run[#{worker_dir}/worker.rb]`
        end
        puts output.inspect
      rescue => e
        RRR.logger.error e.message
      end
    end

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
        RRR.logger.error e.message
      end
    end

  private

    def create_gemfile worker, path
      gemfile = "source 'https://rubygems.org'\n\n"

      gems = @gemfile_default_gems.merge(worker.dependencies || {})
      gems[:run_rabbit_run] = [ { path: '../../../../../' } ] if ['test', 'development'].include? RunRabbitRun.config[:environment]
      gems.each do | gem, args |
        gemfile << "gem '#{gem}'"

        args.each do | arg |
          gemfile << ", #{arg.inspect}"
        end unless args.empty?

        gemfile << "\n"
      end

      File.open(path, 'w') { |f| f.write(gemfile) }
    end

    def report_to_master name
      @master = RRR::Amqp::System.new name, @worker.name
      @worker.on_start { @master.notify :started }
      @worker.on_exit  { @master.notify :finished }
    end
  end
end
