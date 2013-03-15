require "run_rabbit_run/version"

require 'bunny'
require 'amqp'
require 'bson'
require 'logger'

module RunRabbitRun
  require 'run_rabbit_run/master'
  require 'run_rabbit_run/config'

  extend self

  SIGNAL_EXIT   = 'QUIT'
  SIGNAL_RELOAD = 'USR1'
  SIGNAL_KILL   = 'KILL'

  def load_config application_path
    @@config = RunRabbitRun::Config.load(application_path)
  end

  def config
    @@config
  end

  def logger
    @@logger ||= begin
      path = self.config[:log]

      FileUtils.mkdir_p(File.dirname(path)) unless File.exists?(File.dirname(path))

      logger = Logger.new(path, 10, 1024000)

      if self.config[:environment] == 'development'
        logger.level = Logger::DEBUG
      else
        logger.level = Logger::INFO
      end

      logger
    end
  end
end

