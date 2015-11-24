require 'spec_helper'

describe Dyph3::Support::Collater do
  let(:collator) { Dyph3::Support::Collater }
  let(:text)     { "0\n1\n2\n3\n".split(/(\n)/) }
  let(:id)       { ->(x) { x} }
  [ lambda { |x| x.to_s } , lambda { |x| x.to_sym }, lambda { |x| Fish.new(x) } ].each do |f|

    describe ".collate_merge" do
      it "might be empty" do
        results = [{type: :non_conflict, :text=>[]} ]
        expect(collator.collate_merge([],id,nil).results).to eq results
      end

      it "might be have all non_conflicts" do
        collate_merge = text.map { |i| { type: :non_conflict, text: ["#{i}"] }}
        result = [{:type=>:non_conflict, :text=>text}]
        expect(collator.collate_merge(collate_merge, id, nil).results).to eq result
      end

      it "might be have all conflicts" do
        collate_merge = text.map { |i| { type: :conflicts, text: "#{i}" }}
        expect(collator.collate_merge(collate_merge, id, id).results).to eq collate_merge
      end

      it "might be a mixed bag" do
        conflicted_merge = text.map { |i| { type: :conflicts, text: ["#{i}"] }}
        non_conflected_merge = text.map { |i| { type: :non_conflict, text: ["#{i}"] }}
        merge_me = [conflicted_merge, non_conflected_merge].flatten
        result =
        [{:type=>:conflicts, :text=>["0"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:conflicts, :text=>["1"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:conflicts, :text=>["2"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:conflicts, :text=>["3"]},
          {:type=>:conflicts, :text=>["\n"]},
          {:type=>:non_conflict, :text=> text}
        ]
        expect(collator.collate_merge(merge_me, id, id).results).to eq result
      end
    end
  end
end