require 'spec_helper'
describe Dyph3::Differ do
  two_way_differs.each do |current_differ|
    describe current_differ do
      describe ".merge_two_way_diff" do
        it "show all no changes" do
          t1 = "a b c d".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t1, current_differ: current_differ)
          expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange]
        end


        it "should show an add" do
          t1 = "a b c d".split
          t2 = "a b c d e".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, current_differ: current_differ)
          expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Add]
        end

        it "should show a delete" do
          t1 = "a b c d".split
          t2 = "a b c".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, current_differ: current_differ)
          expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete]
        end

        it "should show a change" do
          t1 = "a b c d".split
          t2 = "a b z d".split
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, current_differ: current_differ)
          expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete, Dyph3::Add, Dyph3::NoChange]
        end

        it "should work with this real world complex example" do
          t1 = ["#<Mido::TextBlock::Id id=\"atom_12225_brief_p_0a5374c2bb74790ed958dfb8516a76fc_0\">", "#<Mido::TextBlock::Type name=:p>", ":\"Human \"", ":\"activities \"", ":\"likely \"", ":\"caused \"", ":\"the \"", ":\"Holocene \"", ":\"mass \"", ":extinctions", ":\", \"", ":\"and \"", ":\"many \"", ":\"methods \"", ":\"have \"", ":\"been \"", ":\"employed \"", ":\"to \"", ":\"estimate \"", ":\"these \"", ":\"extinction \"", ":rates", ":\".\"", "#<Mido::TextBlock::Type closed=true name=:p>", "#<Mido::TextBlock::Id closed=true id=\"atom_12225_brief_p_0a5374c2bb74790ed958dfb8516a76fc_0\">"]
          t2 = ["#<Mido::TextBlock::Id id=\"atom_12225_brief_p_27e015d07debd946ef199ab53ce1ca29_0\">", "#<Mido::TextBlock::Type name=:p>", ":\"Human \"", ":\"activities \"", ":\"probably \"", ":\"caused \"", ":\"the \"", ":\"Holocene \"", ":\"mass \"", ":extinctions", ":\"; \"", ":\"many \"", ":\"methods \"", ":\"have \"", ":\"been \"", ":\"employed \"", ":\"to \"", ":\"estimate \"", ":\"these \"", ":\"extinction \"", ":rates", ":\".\"", "#<Mido::TextBlock::Type closed=true name=:p>", "#<Mido::TextBlock::Id closed=true id=\"atom_12225_brief_p_27e015d07debd946ef199ab53ce1ca29_0\">"]
          diff = Dyph3::Differ.merge_two_way_diff(t1, t2, current_differ: current_differ)

          expect(diff.map(&:class)).to eq [ Dyph3::Delete, Dyph3::Add, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete, Dyph3::Add, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete, Dyph3::Delete, Dyph3::Add, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete, Dyph3::Add ]
        end
      end
    end
  end
end
