module RunRabbitRun
  module Config
    class Worker
      attr_accessor :options

      def initialize(path, options = {})
        @options = {
          path:          File.expand_path(path),
          log_to_master: false,
          processes:     1,
        }.merge(options)

        @options[:processes] = 1 unless @options[:processes].to_i >= 0 

        raise "File not exists: #{@options[:path]}" unless File.exists?(@options[:path])
      end

      def options
        @options ||= {}
      end

      def name value
        options[:name] = value
      end

      def processes value
        options[:processes] = value >= 0 ? value : 1
      end

      def log_to_master value
        options[:log_to_master] = !!value
      end

    end
  end
end
