require "run_rabbit_run/version"

require 'amqp'
require 'json'
require 'logger'
require 'socket'

module RRR
  require 'run_rabbit_run/config'
  require 'run_rabbit_run/worker_runner'
  require 'run_rabbit_run/master_runner'

  extend self

  SIGNAL_EXIT   = 'QUIT'
  SIGNAL_INT    = 'INT'
  SIGNAL_TERM   = 'TERM'
  SIGNAL_RELOAD = 'USR1'
  SIGNAL_KILL   = 'KILL'

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
end

