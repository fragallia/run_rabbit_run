require 'daemons'
require 'run_rabbit_run/processes/worker'
require 'run_rabbit_run/amqp'
require 'run_rabbit_run/amqp/system'

module RRR
  module Processes
    module WorkerRunner
      extend self

      @gemfile_default_gems = {
        run_rabbit_run: []
      }

      def build master_name, worker_id, worker_code
        begin
          begin
            worker = eval(worker_code)
          rescue => e
            raise e
          end

          worker_dir = "#{RRR.config[:root]}/tmp/workers/#{RRR.config[:env]}/#{worker.name}"
          FileUtils.mkdir_p(worker_dir) unless File.exists?(worker_dir)

          create_gemfile worker, "#{worker_dir}/Gemfile"

          File.open("#{worker_dir}/worker.rb", 'w') { |f| f.write(worker_code) }
          File.delete("#{worker_dir}/Gemfile.lock") if File.exists?("#{worker_dir}/Gemfile.lock")

          output = ""
          # try to install from local gems
          Bundler.with_clean_env do
            output = `cd #{worker_dir}; bundle install --local --gemfile #{worker_dir}/Gemfile`
          end

          unless File.exists?("#{worker_dir}/Gemfile.lock")
            # if bundle install --local failed run the remote one
            Bundler.with_clean_env do
              output = `cd #{worker_dir}; bundle install --gemfile #{worker_dir}/Gemfile`
            end
          end

          raise "bundle install failed: #{output}" unless File.exists?("#{worker_dir}/Gemfile.lock")

          Bundler.with_clean_env do
            output = `cd #{RRR.config[:root]}; BUNDLE_GEMFILE=#{worker_dir}/Gemfile bundle exec rake rrr:worker:run[#{master_name},#{worker_id},#{worker_dir}/worker.rb]`
          end

        rescue => e
          RRR.logger.error "#{e.message},\n#{e.backtrace.join("\n")}"
        end
      end

      def start master_name, worker_id, file_path
        begin
          worker_code = File.read(file_path)
          worker = eval(worker_code)

          report_to_master master_name, worker, worker_id

          Daemons.run_proc("ruby.rrr.#{worker.name}", RRR.config[:daemons].merge(multiple: true)) do
            worker.run
          end
        rescue => e
          puts "#{e.message},\n#{e.backtrace.join("\n")}"
        end
      end

      def stop pid
        RRR::Utils::Signals.stop_signal(pid)
      end

      def kill pid
        RRR::Utils::Signals.kill_signal(pid)
      end

    private

      def report_to_master master_name, worker, worker_id
        master = RRR::Amqp::System.new master_name, name: worker.name, worker_id: worker_id
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
end
