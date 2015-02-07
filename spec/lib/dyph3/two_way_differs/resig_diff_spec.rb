require 'spec_helper'

describe Dyph3::TwoWayDiffers::ResigDiff do
  describe "monkey" do
    let(:differ) { Dyph3::TwoWayDiffers::ResigDiff }
    describe "complex changes" do
      it "should find a change" do
        t1 = "No TV and no beer and make Homer go crazy".split
        t2 = "No work and much beer make Homer crazy and naked".split
        # t1 = "a b d b".split
        # t2 = "a b c d b".split

        d1 = differ.diff(t1,t2)
        d2 = Dyph3::TwoWayDiffers::HeckelDiff.diff(t1,t2)
        pp d1
        pp d2
      end
    end
  end
end