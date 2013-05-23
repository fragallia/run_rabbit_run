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
      @channel ||= begin
        ch = AMQP::Channel.new(connection, AMQP::Channel.next_channel_id, auto_recovery: true)
        ch.on_error(&method(:handle_channel_exception))

        ch
      end
    end

    def stop delay = 2.0
      EM.add_timer(delay) { connection.close { EM.stop } }
    end

    def handle_channel_exception(channel, channel_close)
      puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
    end
  end
end
