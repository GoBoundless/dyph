$:.push File.expand_path("../lib", __FILE__)
require 'dyph/version'

Gem::Specification.new do |spec|
  spec.name          = "dyph"
  spec.version       = Dyph::VERSION
  spec.authors       = ["Kevin Mook", "Andrew Montalto", "Jacob Elder"]
  spec.email         = ["opensource@boundless.com"]
  spec.description   = %q{A library of useful diffing algorithms for Ruby}
  spec.summary       = %q{A library of useful diffing algorithms for Ruby}
  spec.homepage      = "https://github.com/GoBoundless/dyph"
  spec.license       = "MIT"

  spec.files         = %w( README.md LICENSE )
  spec.files         += Dir.glob("lib/**/*.rb")

  spec.required_ruby_version = '>= 2.2.3'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency 'rspec', '~> 3.3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.2.0'
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'yard'

end