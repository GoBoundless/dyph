require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }
  two_way_differs.product(three_way_differs).each do |diff2, diff3|
    describe "both moves and inserts" do
      subject { Dyph3::Differ.merge(left, base, right, diff2: diff2, diff3: diff3)}
      describe "shuffle text around" do
        let(:joined_result) {
          [
            Dyph3::Outcome::Conflicted.new(base:[], left:[:c, :b], right: [:e]),
            Dyph3::Outcome::Resolved.new([:a]),
            Dyph3::Outcome::Conflicted.new(base: [:b, :c, :d, :e], left:[:d, :e], right: [:c, :d, :b])
          ]
        }
        let(:left)  {[:c, :b, :a, :d, :e]}
        let(:base)  {[:a, :b, :c, :d, :e]}
        let(:right) {[:e, :a, :c, :d, :b]}

        it { expect(subject.joined_results).to eq joined_result }
        it { expect(subject.success?).to be false }
        it { expect(subject.conflict?).to be true }
      end

      describe "should handle when base and left match" do
        let(:left)  { [:a, :b, :c, :d] }
        let(:base)  { [:a, :b, :c] }
        let(:right) { [:b, :c, :d, :e] }
        it { expect(subject.joined_results).to eq right}
        it { expect(subject.success?).to be true}
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle when base and left match" do
        let(:left)  {"ants bears cat dog".split}
        let(:base)  {"ants bears cat dog".split}
        let(:right) {"ants elephant cat bears dog".split}

        it { expect(subject.joined_results).to eq right}
        it { expect(subject.success?).to be true}
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle when base and right match" do
        let(:left) {"ants elephant cat bears dog".split}
        let(:base) {"ants bears cat dog".split}
        let(:right) {"ants bears cat dog".split}

        it { expect(subject.joined_results).to eq left }
        it { expect(subject.success?).to be true }
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle when base and left match" do
        let(:left) {"ants bears cat".split}
        let(:base) {"ants bears cat".split}
        let(:right) {"ants elephant cat bears".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle when the first elements are switched and an insert at the end" do
        let(:left) {"ants bears cat".split}
        let(:base) {"ants bears cat".split}
        let(:right) {"bears ants cat elephant".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle when the last elements are switched and an insert at the beginning" do
        let(:left) {"ants bears cat".split}
        let(:base) {"ants bears cat".split}
        let(:right) {"elephant ants cat bears".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle when all three are different" do
        let(:left) {"ant bear cat monkey goat".split}
        let(:base) {"ant bear cat monkey".split}
        let(:right) {"ant cat bear dog elephant monkey goat".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
        it { expect(subject.conflict?).to be false }
      end

      describe "should handle this really complex real-world case" do
        let(:left) {[ "common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]}
        let(:base) { ["common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]}
        let(:right){ ["right_id_1", "common_h2_open", "right_word_1", "common_word_1", "common_h2_close", "right_id_1_close", "common_id_1", "common_p_open", "common_phrase_1", "common_p_close", "common_id_1_close" ]}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
        it { expect(subject.conflict?).to be false }
      end
    end
  end
end