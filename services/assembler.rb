$:.push File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'run_rabbit_run'

queue = "service.assembler"
options = {
  :auto_delete => false,
  :log_time => true
}

consumer = RunRabbitRun::Consumer.new
consumer.subscribe(queue, options) do | header, payload |
  RunRabbitRun.results_store.set(payload['uuid'], BSON.serialize(payload).to_s)
end

consumer.run
