require 'spec_helper'

describe Dyph3::Support::Collater do
  let(:collator) { Dyph3::Support::Collater }
  let(:text)     { "0\n1\n2\n3\n".split(/(\n)/) } 
  [ lambda { |x| x.to_s } , lambda { |x| x.to_sym }, lambda { |x| Fish.new(x) } ].each do |f|

    describe ".collate_merge" do
      it "might be empty" do
        results =  [[], false, [{type: :non_conflict, :text=>[]} ]]
        expect(collator.collate_merge(f.call(""), f.call(""), f.call(""), [])).to eq results
      end

      it "might be have all non_conflicts" do
        collate_merge = text.map { |i| { type: :non_conflict, text: ["#{i}"] }}
        result = [text, false,
          [{:type=>:non_conflict, :text=>text}]]
        expect(collator.collate_merge(text, text, text, collate_merge)).to eq result
      end

      it "might be have all conflicts" do
        collate_merge = text.map { |i| { type: :conflicts, text: "#{i}" }}
        result = [
          text,
          true,
        collate_merge]
        expect(collator.collate_merge(text, text, text, collate_merge)).to eq result
      end

      it "might be a mixed bag" do
        conflicted_merge = text.map { |i| { type: :conflicts, text: ["#{i}"] }}
        non_conflected_merge = text.map { |i| { type: :non_conflict, text: ["#{i}"] }}
        merge_me = [conflicted_merge, non_conflected_merge].flatten
        result = [
          text,
          true,
        [{:type=>:conflicts, :text=>["0"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:conflicts, :text=>["1"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:conflicts, :text=>["2"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:conflicts, :text=>["3"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:non_conflict, :text=> text}
        ]]
        expect(collator.collate_merge(text, text, text, merge_me)).to eq result
      end
    end
  end
end