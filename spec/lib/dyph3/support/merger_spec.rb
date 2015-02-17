require 'spec_helper'

describe Dyph3::Support::Merger do
  let(:merger)         { Dyph3::Support::Merger }
  describe ".merger" do
    it "should merge nothing" do
      result = []
      expect(merger.merge([],[],[])).to eq result
    end

    it "should a non_conflict" do
      result = [type: :non_conflict, text: 'a']
      expect(merger.merge(['a'],['a'],['a'])).to eq result
    end

    it "should a non_conflict" do
      result = [type: :non_conflict, text: 'b']
      expect(merger.merge(['b'],['a'],['a'])).to eq result
    end

    it "should a conflict" do
      result = [type: :conflict, ours: "b", base: "a", theirs: "c"]
      expect(merger.merge(['b'],['a'],['c'])).to eq result
    end
  end

end