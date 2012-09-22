$:.push File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'run_rabbit_run'

queue_name                    = "service.router"
availability_price_queue_name = "service.availability.price"

options = {
  :auto_delete => false,
  :log_time => true
}

publisher = RunRabbitRun::Publishers::Async.new
consumer  = RunRabbitRun::Consumer.new

consumer.subscribe(queue_name, options) do | header, payload |
  ids = []
  messages_count = 20
  messages_count.times do |i|
    ids << Random.rand(1000000) + 1
  end

  request = {
    :uuid => payload['uuid'],
    :ids => ids,
    :from => payload['from'],
    :to => payload['to']
  }
  
  availability_price_queue ||= RunRabbitRun::Consumer.channel.queue(availability_price_queue_name, :auto_delete => false)

  publisher.send_message(availability_price_queue, request)
end

consumer.run
