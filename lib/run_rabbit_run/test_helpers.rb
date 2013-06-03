module RRR
  module TestHelpers

    def load_worker path
      worker_path = File.expand_path(path)

      raise "Worker file not existing [#{worker_path}]" unless File.exists?(worker_path)

      worker = eval(File.read(worker_path))

      raise "Worker file should evalute into worker class instance" unless worker.is_a?(RRR::Processes::Worker::Base)

      worker.extend(RRR::TestHelpers::TestWorker)
    end

    def create_worker_file text
      file = Tempfile.new('worker')
      file.write text
      file.close

      file.path
    end

    module TestWorker

      def push_message message, opts = {}
        @logger_messages = []
        @sent_messages   = []
        exchange = stub(:exchange)
        channel = stub(:channel)
        channel.stub(:prefetch)
        channel.stub(:direct).and_return(exchange)
        channel.stub(:fanout).and_return(exchange)
        channel.stub(:topic).and_return(exchange)

        RRR::Amqp.stub(:channel).and_return(channel)

        self.queues.each do | name, queue |
          queue.stub(:publish) do | exchange, message, opts, &block |
            @sent_messages << { queue: name, message: message }
          end
        end

        headers = opts[:headers] || begin
          headers = stub(:headers)
          headers.stub(:headers).and_return(RRR::Amqp.default_headers)

          headers
        end

        RRR::Amqp::Queue.any_instance.stub(:subscribe).and_yield(
          headers, JSON.parse(JSON.generate(message))
        )

        EM.run do
          self.run

          EM.stop
        end
      end

      def sent_messages
        @sent_messages || []
      end

      def logger_messages
        @logger_messages || []
      end
    end

  end
end

