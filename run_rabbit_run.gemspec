# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

# include gem version
redis 'run_rabbit_run/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Arturs Kreipans"]
  gem.email         = ["arturs.kreipans@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "run_rabbit_run"
  gem.require_paths = ["lib"]
  gem.version       = RunRabbitRun::VERSION

  gem.add_dependency "mongo"
  gem.add_dependency "bson_ext"
  gem.add_dependency "bunny"
  gem.add_dependency "amqp"
  gem.add_dependency "redis"
end
