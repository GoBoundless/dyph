require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'dyph3'

require "pry"
require "awesome_print"
require 'codeclimate-test-reporter'
require 'faker'

Dir[File.dirname(__FILE__) + '/fixtures/*.rb'].each {|file| require file }

def three_way_differs
  [Dyph3::Support::Diff3, Dyph3::Support::Diff3Beta]
end


def two_way_differs
  [Dyph3::TwoWayDiffers::OriginalHeckelDiff, Dyph3::TwoWayDiffers::HeckelDiff]
end

RSpec.configure do |config|
  config.color = true
end
