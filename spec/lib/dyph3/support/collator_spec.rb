require 'spec_helper'

describe Dyph3::Support::Collater do
  let(:collator) { Dyph3::Support::Collater }
  let(:text)     { "0\n1\n2\n3\n".split(/(\n)/) }
  let(:id)       { ->(x) { x} }
  [ lambda { |x| x.to_s } , lambda { |x| x.to_sym }, lambda { |x| Fish.new(x) } ].each do |f|

    describe ".collate_merge" do
      it "might be empty" do
        results = [Dyph3::Outcome::Resolved.new([]) ]
        expect(collator.collate_merge([],id,nil).results).to eq results
      end

      it "might be have all non_conflicts" do
        collate_merge = text.map { |i| Dyph3::Outcome::Resolved.new(["#{i}"]) }
        result = [Dyph3::Outcome::Resolved.new(text)]
        expect(collator.collate_merge(collate_merge, id, nil).results).to eq result
      end

      it "might be have all conflicts" do
        collate_merge = text.map { |i| Dyph3::Outcome::Conflicted.new(left: "#{i}left", base: "#{i}base",right: "#{i}right" )}
        expect(collator.collate_merge(collate_merge, id, id).results).to eq collate_merge
      end

      it "might be a mixed bag" do
        conflicted_merge = text.map { |i| Dyph3::Outcome::Conflicted.new(left: "#{i}left", base: "#{i}base",right: "#{i}right" )}
        non_conflected_merge = text.map { |i| Dyph3::Outcome::Resolved.new(["#{i}"]) }
        merge_me = [conflicted_merge, non_conflected_merge].flatten
        expect(collator.collate_merge(merge_me, id, id).results).to eq [*conflicted_merge, Dyph3::Outcome::Resolved.new(text)]
      end
    end
  end
end