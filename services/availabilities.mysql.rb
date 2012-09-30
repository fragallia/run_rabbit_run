$:.push File.expand_path("../../lib", __FILE__)
$:.push File.expand_path("../..", __FILE__)

require 'rubygems'
require 'run_rabbit_run'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => "mysql", :host => "localhost", :database => "ht2")

class Availability < ActiveRecord::Base
end

queue_name           = "service.availability.availabilities"
assembler_queue_name = "service.assembler"

options = {
  :auto_delete => false,
  :log_time => true
}

publisher = RunRabbitRun::Publishers::Async.new

consumer  = RunRabbitRun::Consumer.new
consumer.subscribe(queue_name, options) do | header, payload |
  result = []
  Availability.where(['`from` < ? AND `to` > ?', payload['from'].to_date, payload['to'].to_date]).select('property_id').each do | availability |
    result << availability.property_id
  end

  payload['response'] = {'service.availability.availabilities' => {:ids => result}}

  #assembler_queue ||= RunRabbitRun::Consumer.channel.queue(assembler_queue_name, :auto_delete => false)
  #publisher.send_message(assembler_queue, payload)
end

consumer.run
