module MyHelpers
  module WorkerHelpers
    def master_default_headers options = {}
      {
        routing_key: "test.system.master.1",
        persistent: true,
        headers: {
          name: "name",
          created_at: Time.local(2000).to_f,
          pid: Process.pid
        }
      }.merge(options)
    end

    def create_worker_file text
      file = Tempfile.new('worker')
      file.write text
      file.close

      file.path
    end

  end
end

RSpec.configure do |config|
  config.include MyHelpers::WorkerHelpers
end

