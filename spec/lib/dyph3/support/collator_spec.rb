require 'spec_helper'

describe Dyph3::Support::Collater do
  let(:collator) { Dyph3::Support::Collater }

  describe ".collate_merge" do
    it "might be empty" do
      results = ["", false, [{type: :non_conflict, :text=>""}]]
      expect(collator.collate_merge("", "", "", [])).to eq results
    end

    it "might be have all non_conflicts" do
      text = "0\n1\n2\n3\n"
      collate_merge = (0 .. 3).map { |i| { type: :non_conflict, text: "#{i}" }}
      result = [text, false,
        [{:type=>:non_conflict, :text=>text}]]
      expect(collator.collate_merge(text, text, text, collate_merge)).to eq result
    end

    it "might be have all conflicts" do
      text = "0\n1\n2\n3\n"
      collate_merge = (0 .. 3).map { |i| { type: :conflicts, text: "#{i}" }}
      result = [
        text,
        true,
      collate_merge]
      expect(collator.collate_merge(text, text, text, collate_merge)).to eq result
    end

    it "might be a mixed bag" do
      text = "0\n1\n2\n3\n"
      conflicted_merge = (0 .. 3).map { |i| { type: :conflicts, text: "#{i}" }}
      non_conflected_merge = (0 .. 3).map { |i| { type: :non_conflict, text: "#{i}" }}
      merge_me = [conflicted_merge, non_conflected_merge].flatten
      result = [
        text,
        true,
      [{:type=>:conflicts, :text=>"0"},
        {:type=>:conflicts, :text=>"1"},
        {:type=>:conflicts, :text=>"2"},
        {:type=>:conflicts, :text=>"3"},
        {:type=>:non_conflict, :text=>"0\n1\n2\n3\n"}
      ]]

      expect(collator.collate_merge(text, text, text, merge_me)).to eq result
    end
  end
end