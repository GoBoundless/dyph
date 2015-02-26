require 'spec_helper'

describe Dyph3::Support::Merger do
  let(:merger)         { Dyph3::Support::Merger }
  [ lambda { |x| x.to_s } , lambda { |x| x.to_sym }, lambda { |x| Fish.new(x) } ].each do |f|

    describe ".merger" do
      it "should merge nothing" do
        result = []
        expect(merger.merge([],[],[])).to eq result
      end

      it "should a non_conflict" do
        result = [type: :non_conflict, text: 'a']
        expect(merger.merge([f.call('a')],[f.call('a')],[f.call('a')])).to eq result
      end

      it "should a non_conflict" do
        result = [type: :non_conflict, text: 'b']
        expect(merger.merge([f.call('b')],[f.call('a')],[f.call('a')])).to eq result
      end

      it "should a conflict" do
        result = [type: :conflict, ours: f.call("b"), base: f.call("a"), theirs: f.call("c")]
        expect(merger.merge([f.call('b')],[f.call('a')],[f.call('c')])).to eq result
      end
    end
  end
end