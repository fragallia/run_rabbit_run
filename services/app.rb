$:.push File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'run_rabbit_run'

request = RunRabbitRun::Request.new(
  {
    :queue_name => 'service.router',
    :payload => {
      :from => Date.new(2013,3,1).to_time,
      :to => Date.new(2013,3,11).to_time
    },
    :timeout => 5,
    :log_time => true
  }
)

request.run
