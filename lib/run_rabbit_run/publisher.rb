module RunRabbitRun
  class Publisher
    attr_accessor :bunny

    def initialize
      bunny.start
    end

    def bunny
      @bunny ||= Bunny.new
    end

    def exchange
      @exchange ||= bunny.exchange("")
    end

    def send(queue, data, options = {})
      opts = {
        :auto_delete => false
      }.merge(options)

      bunny.queue(queue.name, opts)

      exchange.publish(BSON.serialize(data).to_s, :key => queue.name)
    end

    def stop
      bunny.stop
    end
  end

end
