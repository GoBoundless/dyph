require 'spec_helper'

describe Dyph::Outcome do
  describe "#conflicted?" do
    subject { Dyph::Outcome.new.conflicted? }
    it { is_expected.to be false }
  end

  describe "#resolved?" do
    subject { Dyph::Outcome.new.resolved? }
    it { is_expected.to be false }
  end
end