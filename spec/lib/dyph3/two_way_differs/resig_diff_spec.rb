require 'spec_helper'

describe Dyph3::TwoWayDiffers::ResigDiff do
  describe "" do
    let(:differ_1) { Dyph3::TwoWayDiffers::ResigDiff }
    let(:differ_2) { Dyph3::TwoWayDiffers::HeckelDiff }

    describe "complex changes" do
      it "should find a change" do
        t1 = "a b a a a".split
        t2 = "a a a a b".split
        d1 = differ_1.diff(t1,t2)
        d2 = differ_2.diff(t1,t2)
        expect(d1).to eq d2
      end
    end
  end
end

