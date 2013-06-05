module MyHelpers
  module WorkerHelpers
    def master_default_headers options = {}
      {
        routing_key: "test.system.master.1",
        persistent: true,
        headers: {
          name: 'name',
          created_at: Time.local(2000).to_f,
          pid: Process.pid,
          ip: '1.1.1.1',
          worker_id: 1
        }
      }.merge(options)
    end

  end
end

RSpec.configure do |config|
  config.include MyHelpers::WorkerHelpers
end

