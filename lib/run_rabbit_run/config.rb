require 'run_rabbit_run/config/worker'

module RunRabbitRun
  module Config
    extend self

    attr_accessor :options

    def load(application_path)
      @options = {
        application_path: application_path,
        pid:              "#{application_path}/tmp/pids/run_rabbit_run.pid",
        environment:      (ENV['RAKE_ENV'] || ENV['RAILS_ENV'] || 'development'),
        log:              "log/run_rabbit_run.log",
      }

      load_from_file "#{application_path}/config/rrr.rb"
      load_from_file "#{application_path}/config/rrr/#{@options[:environment]}.rb"

      check_run_statement

      options
    end

    def options
      @options ||= {}  
    end

    def log value
      options[:log] = File.expand_path(value)
    end

    def pid value
      options[:pid] = File.expand_path(value)
    end

    def worker name, path, options = {}, &block
      worker = RunRabbitRun::Config::Worker.new(path, options)
      worker.instance_exec &block if block_given?

      self.options[:workers] ||= {}
      self.options[:workers][name] = worker.options
    end

    def run *workers
      options[:run] = workers
    end

  private

    def load_from_file(path)
      instance_eval File.read(path), path
    end

    def check_run_statement
      diff = options[:run] - options[:workers].keys
      if diff.size > 0
        raise "Configuration error, run statement contains not definded worker name [#{diff.join(',')}]"
      end
    end

  end
end
