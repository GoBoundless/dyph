require 'spec_helper'

describe Dyph3::TwoWayDiffers::OutputConverter do
  let(:converter) { Dyph3::TwoWayDiffers::OutputConverter }
  let(:differ)  { Dyph3::TwoWayDiffers::HeckelDiff }

  describe "work with resig differ" do
    it "should be null" do
      expect(converter.convert_to_dyph3_output([], [])).to eq []
    end

    it "should show an add" do
      t1 = "a b c d".split
      t2 = "a b c d e".split
      diff = differ.execute_diff(t1, t2)
      converted_text = converter.convert_to_dyph3_output(diff[:old_text], diff[:new_text])
      expect(converted_text).to eq [[:add, 5, 4, 5, 5]]
    end

    it "should show a delete" do
      t1 = "a b c d".split
      t2 = "a b c".split
      diff = differ.execute_diff(t1, t2)
      converted_text = converter.convert_to_dyph3_output(diff[:old_text], diff[:new_text])
      expect(converted_text).to eq [[:delete, 4, 4, 4, 3]]
    end

    it "should show a change" do
      t1 = "a b c d".split
      t2 = "a b z d".split
      diff = differ.execute_diff(t1, t2)
      converted_text = converter.convert_to_dyph3_output(diff[:old_text], diff[:new_text])
      expect(converted_text).to eq [[:change, 3, 3, 3, 3]]
    end
  end
end