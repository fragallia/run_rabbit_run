$:.push File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'run_rabbit_run'

queue_name = "service.router"

options = {
  :auto_delete => false,
  :log_time => true
}

publisher = RunRabbitRun::Publishers::Async.new

consumer  = RunRabbitRun::Consumer.new
consumer.subscribe(queue_name, options) do | header, payload |
  if payload['from'] && payload['to']
    if payload['attributes']
      payload['request']   = { :type => :avail, :limit => 5000 }
    else
      payload['request']   = { :type => :avail_attr, :limit => 1000 }
      #TODO make call to attribution service
    end

    availability_queue ||= RunRabbitRun::Consumer.channel.queue('service.availabilities', :auto_delete => false)

    publisher.send_message(availability_queue, payload)
  else
    payload['response']  = {:error => 'Parameters does not match to any search functionality'}
    assembler_queue    ||= RunRabbitRun::Consumer.channel.queue('service.assembler', :auto_delete => false)

    publisher.send_message(assembler_queue, payload)
  end

end

consumer.run
