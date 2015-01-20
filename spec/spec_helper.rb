require "pry"
require "awesome_print"
require 'codeclimate-test-reporter'

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
end

require 'dyph3'