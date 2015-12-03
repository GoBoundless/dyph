$:.push File.expand_path("../lib", __FILE__)
require 'dyph3/version'

Gem::Specification.new do |spec|
  spec.name          = "dyph3"
  spec.version       = Dyph3::VERSION
  spec.authors       = ["Kevin Mook"]
  spec.email         = ["kevin@boundless.com"]
  spec.description   = %q{Dyph3 is a pure-ruby implementation of the diff3 algorithm}
  spec.summary       = %q{Dyph3 is a pure-ruby implementation of the diff3 algorithm}
  spec.homepage      = "https://github.com/GoBoundless/dyph3"
  spec.license       = "MIT"

  spec.files         = %w( README.md LICENSE )
  spec.files         += Dir.glob("lib/**/*.rb")

  spec.required_ruby_version = '>= 2.2.1'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency 'rspec', '~> 3.3.0'
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'faker'

end