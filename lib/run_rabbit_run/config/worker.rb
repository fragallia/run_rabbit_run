module RunRabbitRun
  module Config
    class Worker
      attr_accessor :options
      
      def initialize(path, options = {})
        @options = {
          path: File.expand_path(path),
        }.merge(options)

        raise "File not exists: #{@options[:path]}" unless File.exists?(@options[:path])
      end

      def options
        @options ||= {}
      end
     
      def name value
        options[:name] = value
      end

    end
  end
end
