require "run_rabbit_run/version"
require 'date'
require 'redis'

module RunRabbitRun

  require 'run_rabbit_run/collector'
  require 'run_rabbit_run/request'
  require 'run_rabbit_run/response'
  require 'run_rabbit_run/consumer'

  module Publishers
    require 'run_rabbit_run/publishers/sync'
    require 'run_rabbit_run/publishers/async'
  end

  class << self
    def collector
      @collector ||= RunRabbitRun::Collector
    end

    def results_store
      @results_store ||= Redis.new
    end

  end
end
