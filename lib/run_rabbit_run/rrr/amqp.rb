module RRR
  module Amqp
    extend self
    
    def start
      connection
      channel
    end

    def connection
      @connection ||= begin
        con = AMQP.connect(RunRabbitRun::Config.options[:rabbitmq])
        
        AMQP.connection = con

        con
      end
    end

    def channel
      @channel    ||= AMQP::Channel.new(connection, AMQP::Channel.next_channel_id, auto_recovery: true)
    end

    def stop
      EM.add_timer(2.0) { connection.close { EventMachine.stop } }
    end
  end
end
