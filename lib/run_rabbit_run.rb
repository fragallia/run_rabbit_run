require "run_rabbit_run/version"

require 'bunny'
require 'amqp'
require 'bson'

module RunRabbitRun
  require 'run_rabbit_run/publisher'
  require 'run_rabbit_run/queue'
  require 'run_rabbit_run/master'
  require 'run_rabbit_run/config'

  require 'run_rabbit_run/base'
  include RunRabbitRun::Base

  extend self

  SIGNAL_EXIT   = 'QUIT'
  SIGNAL_RELOAD = 'USR1'
  SIGNAL_KILL   = 'KILL'

  def load_config(application_path)
    @@config = RunRabbitRun::Config.load(application_path)
  end

  def config
    @@config
  end
end

