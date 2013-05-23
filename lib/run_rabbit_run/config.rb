module RRR
  module Config
    extend self

    attr_accessor :options

    def load(root)
      @options = {
        root:     root,
        env:      (ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'),
        pid:      "#{root}/tmp/pids",
        log:      "#{root}/log",
        rabbitmq: {}
      }

      load_from_file "#{root}/config/rrr.rb" if File.exists? "#{root}/config/rrr.rb"
      load_from_file "#{root}/config/rrr/#{@options[:env]}.rb" if File.exists? "#{root}/config/rrr/#{@options[:env]}.rb"

      options
    end

    def options
      @options ||= {}
    end

    def pid value
      options[:pid] = File.expand_path(value)
    end

    def log value
      options[:log] = File.expand_path(value)
    end

    def env value
      options[:env] = value
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

  end
end
