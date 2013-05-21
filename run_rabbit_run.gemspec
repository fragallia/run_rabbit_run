# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

# include gem version
require 'run_rabbit_run/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Arturs Kreipans"]
  gem.email         = ["arturs.kreipans@gmail.com"]
  gem.description   = %q{RunRabbitRun gem lets to run and manage multiple ruby processes for RabbitMQ}
  gem.summary       = %q{RunRabbitRun gem lets to run and manage multiple ruby processes for RabbitMQ}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "run_rabbit_run"
  gem.require_paths = ["lib"]
  gem.version       = RunRabbitRun::VERSION

  gem.add_dependency "rake"
  gem.add_dependency "bson_ext"
  gem.add_dependency "amqp"
  #TODO remove this dependency
  gem.add_dependency "bunny"
  gem.add_dependency "daemons"

  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'evented-spec'
end
