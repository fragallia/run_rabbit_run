require 'run_rabbit_run/config/worker'

module RunRabbitRun
  module Config
    extend self

    attr_accessor :options

    def load(application_path)
      @options = {
        application_path: application_path,
        pid:              "#{application_path}/tmp/pids/run_rabbit_run.pid",
        guid:             "#{application_path}/tmp/pids/run_rabbit_run.guid",
        environment:      (ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'),
        log:              "log/run_rabbit_run.log",
        rabbitmq:         {}
      }

      if File.exists? "#{application_path}/config/rrr.rb"
        load_from_file "#{application_path}/config/rrr.rb"
      else
        puts "Config [#{application_path}/config/rrr.rb] not found" if @options[:environment] != 'test'
      end

      if File.exists? "#{application_path}/config/rrr/#{@options[:environment]}.rb"
        load_from_file "#{application_path}/config/rrr/#{@options[:environment]}.rb"
      else
        puts "Config [#{application_path}/config/rrr/#{@options[:environment]}.rb] not found" if @options[:environment] != 'test'
      end

      check_run_statement if options[:run]

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

    def guid value
      options[:guid] = File.expand_path(value)
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

    def env value
      options[:environment] = value
    end

    def rabbitmq rmqoptions
      case rmqoptions
      when String
      when Hash
        if rmqoptions.keys.find { | key | !key.is_a? Symbol }
          raise "ERROR: Only symbol as a key is allowed for rabbitmq options!"
        end
      else
        raise "Hash or String only is allowed as rabbitmq options"
      end
      options[:rabbitmq] = rmqoptions
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
