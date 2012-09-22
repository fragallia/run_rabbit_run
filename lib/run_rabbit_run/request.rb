require 'securerandom'
require 'run_rabbit_run/callbacks/base'

module RunRabbitRun
  class Request
    include RunRabbitRun::Callbacks::Base

    attr_accessor :queue_name, :payload, :response, :timeout, :log_time

    def initialize(options)
      @queue_name = options.fetch(:queue_name, "service.search")
      @payload    = options.fetch(:payload, {})
      @publisher  = options.fetch(:publisher, Publishers::Sync.new([@queue_name]))
      @timeout    = options.fetch(:timeout, 1)
      @log_time   = options.fetch(:log_time, false)
    end

    def run
      puts "[#{@queue_name}] [#{Time.now.to_f}] started" if @log_time

      @payload['uuid'] = generate_unique_request_id

      @publisher.send_message(@queue_name, @payload)

      @response = RunRabbitRun.collector.fetch(@payload['uuid'], @timeout)

      execute_callbacks

      puts "[#{@queue_name}] [#{Time.now.to_f}] finished" if @log_time
    end

    def generate_unique_request_id
      "#{SecureRandom.uuid}-#{Time.now.to_f}"
    end
  end

end
