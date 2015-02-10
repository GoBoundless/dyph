require 'spec_helper'

describe Dyph3::TwoWayDiffers::ResigDiff do
  describe "" do
    let(:differ) { Dyph3::TwoWayDiffers::ResigDiff }
    describe "complex changes" do
      xit "should find a change" do
        t1 = "No TV and no beer make Homer go crazy".split
        t2 = "No work and much beer make Homer crazy and naked".split
        d1 = differ.diff(t1,t2)
        expect(d1).to eq 'test'
      end
    end
  end
end