$:.push File.expand_path("../../lib", __FILE__)
$:.push File.expand_path("../..", __FILE__)

require 'rubygems'
require 'run_rabbit_run'
require 'mongo'

require 'services/prices/calculator'

@conn = Mongo::Connection.new
@db   = @conn['ht2']
@coll = @db['availabilities']

def build_availability_query(from, to)
  {
    'availabilities' => {
      '$elemMatch' => {
        'from' => {'$lte' => from.to_i},
        'to'   => {'$gte' => to.to_i}
      }
    }
  }
end

def build_location_query(location)
  {
    'location' => location
  }
end

queue_name           = "service.availabilities"
assembler_queue_name = "service.assembler"

options = {
  :auto_delete => false,
  :log_time => true
}

publisher = RunRabbitRun::Publishers::Async.new

consumer  = RunRabbitRun::Consumer.new
consumer.subscribe(queue_name, options) do | header, payload |
  result = []
  document = {}
  if payload['from'] && payload['to']
    document.merge!(build_availability_query(payload['from'], payload['to']))
  end
  document.merge!(build_location_query(payload['location'])) if payload['location']

  options = { :sort => ['sqs', Mongo::DESCENDING], :fields => {'sqs' => 1} }
  if payload.fetch('request', {})['limit']
    options[:limit] = payload['request']['limit']
  end

  @coll.find(document, options).each do | record |
    result << [record['_id'], record['sqs']]
  end

puts result.size

  payload['response'] = {'service.attribution' => {:ids => result}}

  #assembler_queue ||= RunRabbitRun::Consumer.channel.queue(assembler_queue_name, :auto_delete => false)
  #publisher.send_message(assembler_queue, payload)
end

consumer.run
