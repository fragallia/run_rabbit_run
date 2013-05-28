require 'run_rabbit_run'
require 'run_rabbit_run/test_helpers'
require 'rspec'
require 'evented-spec'
require 'timecop'

ENV["RACK_ENV"] ||= 'test'

$:.push File.expand_path("../", __FILE__)

RRR.load_config(File.expand_path('.'))

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob(File.expand_path('.', "spec/support/**/*.rb")).each {|f| require f}

RSpec.configure do |c|
  c.include RRR::TestHelpers

  c.mock_with :rspec
end
