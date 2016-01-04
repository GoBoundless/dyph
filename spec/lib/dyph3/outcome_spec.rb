require 'spec_helper'

describe Dyph3::Outcome do
  describe "#conflicted?" do
    subject { Dyph3::Outcome.new.conflicted? }
    it { is_expected.to be false }
  end

  describe "#resolved?" do
    subject { Dyph3::Outcome.new.resolved? }
    it { is_expected.to be false }
  end
end