require 'daemons'
require 'run_rabbit_run/worker'
require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/system'

module RRR
  module WorkerRunner
    extend self

    @gemfile_default_gems = {
      run_rabbit_run: []
    }

    def build master_name, worker_code
      begin
        begin
          worker = eval(worker_code)
        rescue => e
          raise 'worker evaluates with exceptions'
        end

        worker_dir = "#{RRR.config[:root]}/tmp/workers/#{RRR.config[:env]}/#{worker.name}"
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
          output = `cd #{RRR.config[:root]}; BUNDLE_GEMFILE=#{worker_dir}/Gemfile bundle exec rake rrr:worker:run[#{master_name},#{worker_dir}/worker.rb]`
        end

      rescue => e
        RRR.logger.error e.message
      end
    end

    def start master_name, file_path
      begin
        worker_code = File.read(file_path)
        worker = eval(worker_code)

        report_to_master master_name, worker

        Daemons.run_proc("ruby.rrr.#{worker.name}", RRR.config[:daemons].merge(multiple: true)) do
          worker.run
        end
      rescue => e
        RRR.logger.error e.message
      end
    end

    def stop pid
      RRR::Utils::Signals.stop_signal(pid)
      while RRR::Utils::Signals.running?(pid)
        sleep 0.1
      end
    end

  private

    def report_to_master master_name, worker
      master = RRR::Amqp::System.new master_name, worker.name
      worker.on_start { master.notify(:started) }
      worker.on_exit  { master.notify(:finished) }
    end

    def create_gemfile worker, path
      gemfile = "source 'https://rubygems.org'\n\n"

      gems = @gemfile_default_gems.merge(worker.dependencies || {})
      gems[:run_rabbit_run] = [ { path: '../../../../../' } ] if ['test', 'development'].include? RRR.config[:env]
      gems.each do | gem, args |
        gemfile << "gem '#{gem}'"

        args.each do | arg |
          gemfile << ", #{arg.inspect}"
        end unless args.empty?

        gemfile << "\n"
      end

      File.open(path, 'w') { |f| f.write(gemfile) }
    end

  end
end
