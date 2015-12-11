require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }
  two_way_differs.each do |current_differ|
    describe "both moves and inserts" do
      subject { Dyph3::Differ.merge(left, base, right, current_differ: current_differ) }
      describe "should handle when base and left match" do
        let(:left)  {"ants bears cat dog".split}
        let(:base)  {"ants bears cat dog".split}
        let(:right) {"ants elephant cat bears dog".split}

        it { expect(subject.joined_results).to eq right}
        it { expect(subject.success?).to be true}
      end

      describe "should handle when base and right match" do
        let(:left) {"ants elephant cat bears dog".split}
        let(:base) {"ants bears cat dog".split}
        let(:right) {"ants bears cat dog".split}

        it { expect(subject.joined_results).to eq left }
        it { expect(subject.success?).to be true }
      end

      describe "should handle when base and left match" do
        let(:left) {"ants bears cat".split}
        let(:base) {"ants bears cat".split}
        let(:right) {"ants elephant cat bears".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
      end

      describe "should handle when the first elements are switched and an insert at the end" do
        let(:left) {"ants bears cat".split}
        let(:base) {"ants bears cat".split}
        let(:right) {"bears ants cat elephant".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
      end

      describe "should handle when the last elements are switched and an insert at the beginning" do
        let(:left) {"ants bears cat".split}
        let(:base) {"ants bears cat".split}
        let(:right) {"elephant ants cat bears".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
      end

      describe "should handle when all three are different" do
        let(:left) {"ant bear cat monkey goat".split}
        let(:base) {"ant bear cat monkey".split}
        let(:right) {"ant cat bear dog elephant monkey goat".split}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
      end

      describe "should handle this really complex real-world case" do
        let(:left) {[ "common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]}
        let(:base) { ["common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]}
        let(:right){ ["right_id_1", "common_h2_open", "right_word_1", "common_word_1", "common_h2_close", "right_id_1_close", "common_id_1", "common_p_open", "common_phrase_1", "common_p_close", "common_id_1_close" ]}

        it { expect(subject.joined_results).to eq right }
        it { expect(subject.success?).to be true }
      end
    end
  end
end