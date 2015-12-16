require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }
  #conflict function just applys a join on each outcome item
  let(:conflict_function) { ->(xs) { xs.map { |x| x.apply(->(array) {array.join})}} }
  let(:resloved)    { Dyph3::Outcome::Resolved }
  let(:conflicted)  { Dyph3::Outcome::Conflicted }
  # [Dyph3::TwoWayDiffers::ResigDiff, Dyph3::TwoWayDiffers::HeckelDiff].each do |diff2|
  two_way_differs.product(three_way_differs).each do |diff2, diff3|
    describe "testing multiple types of conflicts" do
      subject { Dyph3::Differ.merge(left, base, right,
                join_function: Dyph3::Differ.standard_join,
                split_function: Dyph3::Differ.split_on_new_line,
                conflict_function: conflict_function,
                diff2: diff2, diff3: diff3)
      }

      describe "first object conflict" do
        let(:left)  { "left change\nalpha\nbeta" }
        let(:base)  { "base change\nalpha\nbeta" }
        let(:right) { "right change\nalpha\nbeta" }
        let(:expected_result) { [
          conflicted.new(left: "left change\n", base: "base change\n", right: "right change\n"),
          resloved.new("alpha\nbeta")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe "a conflict in the last line" do
        let(:left) {"alpha\nbeta\nleft change"}
        let(:base) {"alpha\nbeta\nbase change"}
        let(:right){"alpha\nbeta\nright change"}
        let(:expected_result) {[
          resloved.new("alpha\nbeta\n"),
          conflicted.new(left: "left change", base: "base change", right: "right change")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe "a conflict in the center" do
        let(:left) {"alpha\nleft change\nbeta"}
        let(:base) {"alpha\nbase change\nbeta"}
        let(:right){"alpha\nright change\nbeta"}
        let(:expected_result) {[
          resloved.new("alpha\n"),
          conflicted.new(left: "left change\n", base: "base change\n", right: "right change\n"),
          resloved.new("beta")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe 'should handle overlapping conflicts' do
        let(:left) {"alpha\nleft_1\nleft_2\nleft_3\ndelta\n"}
        let(:base) {"alpha\nbase_1\nbase_2\nbase_3\ndelta\n"}
        let(:right) {"alpha\nright_1\nright_2\nright_3\ndelta\n"}
        let(:expected_result) {[
          resloved.new("alpha\n"),
          conflicted.new(
            left: "left_1\nleft_2\nleft_3\n",
            base: "base_1\nbase_2\nbase_3\n",
            right: "right_1\nright_2\nright_3\n"),
          resloved.new("delta\n")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe "should handle a conflict, non_conflict, conflict pattern" do
        let(:left)  {"ALPHA\nBETA\nGAMMA\n"}
        let(:base)  {"alpha alpha\nBETA\ngamma gamma\n"}
        let(:right) {"alpha\nBETA\ngamma\n"}

        let(:expected_result) {[
          conflicted.new(left: "ALPHA\n", base: "alpha alpha\n", right: "alpha\n"),
          resloved.new("BETA\n"),
          conflicted.new(left: "GAMMA\n", base: "gamma gamma\n", right: "gamma\n")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe 'periodic conflicts' do
        let(:base)  {"alpha\nbase change 1\nbeta\nbase change 2\ndelta\nbase change 3"}
        let(:left)  {"alpha\nleft change 1\nbeta\nleft change 2\ndelta\nleft change 3"}
        let(:right) {"alpha\nright change 1\nbeta\nright change 2\ndelta\nright change 3"}

        let(:expected_result) {[
          resloved.new("alpha\n"),
          conflicted.new(left:"left change 1\n",  base: "base change 1\n", right:"right change 1\n"),
          resloved.new("beta\n"),
          conflicted.new(left:"left change 2\n", base:"base change 2\n", right: "right change 2\n"),
          resloved.new("delta\n"),
          conflicted.new(left: "left change 3", base:"base change 3", right:"right change 3")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe 'should handle non overlapping base changes without conflicts' do
        let(:left)  {"alpha\nLEFT CHANGE\ngamma\ndelta\nepsilon\n"}
        let(:base)  {"alpha\nalpha\ngamma\ndelta\nepsilon\n"}
        let(:right) {"alpha\nalpha\ngamma\nRIGHT CHANGE\nepsilon\n"}
        let(:expected_result) {"alpha\nLEFT CHANGE\ngamma\nRIGHT CHANGE\nepsilon\n"}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq false}
      end

      describe "partial deletion of the first half of a line" do
        let(:base)  {"base change\nalpha"}
        let(:left)  {"alpha"}
        let(:right) {"some text\nalpha"}
        let(:expected_result) {[
           conflicted.new(left:"", base:"base change\n", right: "some text\n"),
           resloved.new("alpha")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe "both sides deleting, but one side deleting more" do
        let(:base)  {"alpha\nbase change\nbeta"}
        let(:left)  {"alpha\nbeta"}
        let(:right) {"alpha\nright change\nbeta"}
        let(:expected_result) {[
          resloved.new("alpha\n"),
          conflicted.new(
            left: "",
            base: "base change\n",
            right: "right change\n"),
          resloved.new("beta")
        ]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end

      describe 'should handle a creation of two different things' do
        let(:left) {"apple"}
        let(:base) {""}
        let(:right) {"apricot"}
        let(:expected_result) {[ conflicted.new(left: "apple", base: "", right: "apricot")]}

        it {expect(subject.joined_results).to eq expected_result}
        it {expect(subject.conflict?).to eq true}
      end
    end
  end
end