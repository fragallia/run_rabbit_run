$:.push File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'run_rabbit_run'

request = RunRabbitRun::Request.new(
  {
    :queue_name => 'service.router',
    :payload => {
      :from => 20131201,
      :to => 20131211,
      #:location => 1000
    },
    :timeout => 5,
    :log_time => true
  }
)

request.run
