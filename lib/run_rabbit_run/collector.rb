
module RunRabbitRun
  module Collector
    extend self

    def fetch(uuid, timeout)
      start = Time.now.to_f
      until res = RunRabbitRun.results_store.get(uuid)
        sleep 0.001
        break if Time.now.to_f - start  > timeout
      end

      RunRabbitRun::Response.new(BSON.deserialize(res.unpack("C*")))
    end
  end
end
