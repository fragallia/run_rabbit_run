require "run_rabbit_run/version"

require 'amqp'
require 'json'
require 'logger'
require 'socket'

module RRR
  require 'run_rabbit_run/config'
  require 'run_rabbit_run/processes/worker_runner'
  require 'run_rabbit_run/processes/master_runner'

  extend self

  @@config = {}

  def load_config root
    @@config = RRR::Config.load(root)
  end

  def config
    @@config
  end

  def logger
    @@logger ||= begin
      path = RRR.config[:log]

      FileUtils.mkdir_p(File.dirname(path)) unless File.exists?(File.dirname(path))

      logger = Logger.new(path, 10, 1024000)

      if RRR.config[:env] == 'development'
        logger.level = Logger::DEBUG
      else
        logger.level = Logger::INFO
      end

      logger
    end
  end

  def logger=(value)
    @@logger = value
  end

  module Loadbalancer
    require 'run_rabbit_run/loadbalancer/base'
  end
end

