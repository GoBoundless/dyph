require 'spec_helper'
describe Dyph3::Differ do
  two_way_differs.each do |diff2|
    describe diff2 do
      describe ".merge_two_way_diff" do
        it "show all no changes" do
          t1 = "a b c d".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t1, diff2: diff2)
          expect(diff.map(&:class)).to eq [Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange]
        end
       
        it "should show an add" do
          t1 = "a b c d".split
          t2 = "a b c d e".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, diff2: diff2)
          expect(diff.map(&:class)).to eq [Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::Add]
        end

        it "should show a delete" do
          t1 = "a b c d".split
          t2 = "a b c".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, diff2: diff2)
          expect(diff.map(&:class)).to eq [Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::Delete]
        end

        it "should show a change" do
          t1 = "a b c d".split
          t2 = "a b z d".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, diff2: diff2)
          expect(diff.map(&:class)).to eq [Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::Delete, Dyph3::Action::Add, Dyph3::Action::NoChange]
        end

        it "should work with this real world complex example" do
          t1 = ["t1_001", "s1", "s2", "s3", "t1_002", "s4", "s5", "s6", "s7", "s8", "t1_003", "t1_004", "s9", "s10", "s11", "s12", "s13", "s14", "s15", "s16", "s17", "s18", "s19", "s20", "t1_005"]
          t2 = ["t2_001", "s1", "s2", "s3", "t2_002", "s4", "s5", "s6", "s7", "s8", "t2_003", "s9", "s10", "s11", "s12", "s13", "s14", "s15", "s16", "s17", "s18", "s19", "s20", "t2_005"]
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, diff2: diff2)

          expect(diff.map(&:class)).to eq [ Dyph3::Action::Delete, Dyph3::Action::Add, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::Delete, Dyph3::Action::Add, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::Delete, Dyph3::Action::Delete, Dyph3::Action::Add, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::NoChange, Dyph3::Action::Delete, Dyph3::Action::Add ]
        end
      end
    end
  end
end
