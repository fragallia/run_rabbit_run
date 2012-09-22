module RunRabbitRun
  class Response
    attr_accessor :payload

    def initialize(payload)
      @payload = payload
    end

    def data
      @payload
    end

    def success?
      !@payload.nil?
    end
  end
end
