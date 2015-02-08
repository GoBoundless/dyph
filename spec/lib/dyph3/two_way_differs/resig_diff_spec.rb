require 'spec_helper'

describe Dyph3::TwoWayDiffers::ResigDiff do
  describe "monkey" do
    let(:differ) { Dyph3::TwoWayDiffers::ResigDiff }
    describe "complex changes" do
      it "should find a change" do
        t1 = "No TV and no beer make Homer go crazy".split
        t2 = "No work and much beer make Homer crazy and naked".split
        t3 = "No TV and wearing clothes make Homer go crazy".split
        # t1 = "b a d b".split
        # t2 = "b a c d b".split

        d1 = differ.diff(t1,t3)
        d2 = Dyph3::TwoWayDiffers::HeckelDiff.diff(t1,t3)
        pp d1
        pp d2
        x = Dyph3::Differ.merge_text t2.join("\n"), t1.join("\n"), t3.join("\n")
        puts x
        binding.pry
      end
    end
  end
end