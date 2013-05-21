require 'run_rabbit_run'
require 'rspec'
require 'evented-spec'
require 'timecop'

ENV["RACK_ENV"] ||= 'test'

RunRabbitRun.load_config(File.expand_path('.'))

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob(File.expand_path('.', "spec/support/**/*.rb")).each {|f| require f}

RSpec.configure do |c|
  c.mock_with :rspec
end
