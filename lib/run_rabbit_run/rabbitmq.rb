module RunRabbitRun
  module Rabbitmq
    require 'run_rabbit_run/rabbitmq/publisher'
    require 'run_rabbit_run/rabbitmq/queue'

    extend self

    def queue
      RunRabbitRun::Rabbitmq::Queue
    end

    def subscribe(queue, options = {}, &block)
      opts = options.dup
      time_loging = opts.delete(:time_loging) || false

      queue.subscribe do | header, payload |
        RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] started" if time_loging
        doc = BSON.deserialize(payload.unpack("C*"))
        instance_exec(header, doc, &block)
        RunRabbitRun.logger.info "[#{queue.name}] [#{Time.now.to_f}] finished" if time_loging
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
      @@publisher  ||= RunRabbitRun::Rabbitmq::Publisher.new
    end

    def stop
      publisher.stop

      connection.close {
        EventMachine.stop { exit }
      }
    end

  private

    def handle_channel_exception(channel, channel_close)
      RunRabbitRun.logger.error "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"

      self.stop
    end # handle_channel_exception
  end
end
