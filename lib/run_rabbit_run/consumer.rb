require 'amqp'

module RunRabbitRun
  class Consumer
    attr_accessor :queues, :exchange
    
    class << self
      def connection
        @@connection ||= AMQP.connect(:host => '127.0.0.1')
      end

      def channel
        @@channel ||= AMQP::Channel.new(connection)
      end
    end

    def initialize
      @queues = []
    end # initialize
    
    def subscribe(queue, options, &block)
      @queues << {:name => queue, :options => options, :handler => block}
    end # start

    def send_message(queue_name, payload)
      @exchange.publish(BSON.serialize(payload).to_s, :routing_key => queue_name)
    end

    def run
      EventMachine.run do
        Consumer.channel.on_error(&method(:handle_channel_exception))

        @queues.each do | queue_data | 
          AMQP::Queue.new(Consumer.channel, queue_data[:name], queue_data[:options]) do | queue |
            queue.subscribe do | header, payload |
              puts "[#{queue.name}] [#{Time.now.to_f}] started" if queue_data[:options][:log_time]
              doc = BSON.deserialize(payload.unpack("C*"))
              queue_data[:handler].call(header, doc)
              puts "[#{queue.name}] [#{Time.now.to_f}] finished" if queue_data[:options][:log_time]
            end
          end
        end
      end
    end
    
    def handle_channel_exception(channel, channel_close)
      puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"

      connection.close {
        EM.stop { exit }
      }
    end # handle_channel_exception(channel, channel_close)
  end
end
