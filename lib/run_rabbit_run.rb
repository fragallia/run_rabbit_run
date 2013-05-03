require "run_rabbit_run/version"

require 'amqp'
require 'bson'
require 'json'
require 'logger'
require 'socket'

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
    @@logger ||= MQLogger.new
  end

  def local_logger
    @@local_logger ||= begin
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

  class MQLogger
    
    def info(message)
      exchange.publish(_message(message), :routing_key => "info")
    end

    def error(message)
      exchange.publish(_message(message), :routing_key => "exception")
    end

    def debug(message)
      exchange.publish(_message(message), :routing_key => "debug")
    end

    def connection
      @connection ||= AMQP.connect(RunRabbitRun::Config.options[:rabbitmq])
    end

    def channel
      @channel    ||= AMQP::Channel.new(connection, AMQP::Channel.next_channel_id, auto_recovery: true)
    end

    def exchange
      @exchange ||= channel.topic("log")
    end

    private 

    def _message(message)
      JSON.generate({message: message, host: Socket.gethostname})
    end

  end
end

