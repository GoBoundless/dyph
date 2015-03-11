require "pry"
require "awesome_print"
require 'codeclimate-test-reporter'
Dir[File.dirname(__FILE__) + '/fixtures/*.rb'].each {|file| require file }

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
end

require 'dyph3'