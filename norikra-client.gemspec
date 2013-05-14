# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'norikra/client/version'

Gem::Specification.new do |spec|
  spec.name          = "norikra-client"
  spec.version       = Norikra::Client::VERSION
  spec.authors       = ["TAGOMORI Satoshi"]
  spec.email         = ["tagomoris@gmail.com"]
  spec.description   = %q{Client commands and libraries for Norikra}
  spec.summary       = %q{Client commands and libraries for Norikra}
  spec.homepage      = "https://github.com/tagomoris/norikra-client"
  spec.license       = "APLv2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "msgpack-rpc-over-http", "~> 0.0.4"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "ltsv"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
