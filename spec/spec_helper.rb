require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'dyph3'

require "pry"
require "awesome_print"
require 'codeclimate-test-reporter'

Dir[File.dirname(__FILE__) + '/fixtures/*.rb'].each {|file| require file }

RSpec.configure do |config|
  config.color = true
end
