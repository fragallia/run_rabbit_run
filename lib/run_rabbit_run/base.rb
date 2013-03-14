module RunRabbitRun
  module Base
    def start(&block)
      EventMachine.run do
        instance_exec(&block)
      end
    end

    def subscribe(queue, options = {}, &block)
      AMQP::Queue.new(RunRabbitRun.channel, queue.name, queue.options) do | queue |
        queue.subscribe do | header, payload |
          #puts "[#{queue.name}] [#{Time.now.to_f}] started"
          doc = BSON.deserialize(payload.unpack("C*"))
          instance_exec(header, doc, &block)
          #puts "[#{queue.name}] [#{Time.now.to_f}] finished"
        end
      end
    end

    def send(queue, data)
      publisher.send(queue, data)
    end

    def connection
      @@connection ||= AMQP.connect(:host => '127.0.0.1')
    end

    def channel
      @@channel    ||= AMQP::Channel.new(connection)
    end

    def publisher
      @@publisher  ||= RunRabbitRun::Publisher.new
    end

  private

    def handle_channel_exception(channel, channel_close)
      puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"

      publisher.stop

      connection.close {
        EM.stop { exit }
      }
    end # handle_channel_exception
  end
end
