$:.push File.expand_path("../../lib", __FILE__)
$:.push File.expand_path("../..", __FILE__)

require 'rubygems'
require 'run_rabbit_run'
require 'mongo'

require 'services/prices/calculator'

@conn = Mongo::Connection.new
@db   = @conn['ht2']
@coll = @db['prices']

queue_name           = "service.availability.price"
assembler_queue_name = "service.assembler"

options = {
  :auto_delete => false,
  :log_time => true
}

publisher = RunRabbitRun::Publishers::Async.new

consumer  = RunRabbitRun::Consumer.new
consumer.subscribe(queue_name, options) do | header, payload |
  payload['id.price'] = []
  @coll.find({'_id' => {'$in' => payload['ids']}}).each do | record |
    payload['id.price'] << [record['_id'], Prices::Calculator.calculate(record, payload['from'], payload['to'])]
  end

  assembler_queue ||= RunRabbitRun::Consumer.channel.queue(assembler_queue_name, :auto_delete => false)

  publisher.send_message(assembler_queue, payload)
end

consumer.run
