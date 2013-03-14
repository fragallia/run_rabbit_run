require 'run_rabbit_run/config/worker'

module RunRabbitRun
  module Config
    extend self

    attr_accessor :options

    def load(application_path)
      @options = {
        application_path: application_path,
        pid:              "#{application_path}/tmp/pids/run_rabbit_run.pid"
      }

      config_file = "#{application_path}/config/rrr.rb"
      instance_eval File.read(config_file), config_file

      environment = ENV['RAKE_ENV'] || ENV['RAILS_ENV'] || 'development'

      rake_environment_file = "#{application_path}/config/rrr/#{environment}.rb"
      instance_eval File.read(rake_environment_file), rake_environment_file

      options
    end

    def options
      @options ||= {}  
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
  end
end
