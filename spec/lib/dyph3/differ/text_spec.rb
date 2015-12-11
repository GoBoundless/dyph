require 'spec_helper'
describe Dyph3::Differ do
  #conflict function just applys a join on each outcome item
  let(:conflict_function) { ->(xs) { xs.map { |x| x.apply(->(array) {array.join})}} }
  let(:text_split) { Dyph3::Differ.split_on_new_line }
  let(:text_join)  { Dyph3::Differ.standard_join }

  two_way_differs.each do |current_differ|
    describe "merging text" do
      let(:base) { "This is the baseline.\nThe start.\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}
      let(:left) { "This is the baseline.\nThe start (changed by A).\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}
      let(:right) {"This is the baseline.\nThe start.\nB added this line.\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

      let(:expected_result){
        [
          Dyph3::Outcome::Resolved.new(["This is the baseline.\n"]),
          Dyph3::Outcome::Conflicted.new(left: ["The start (changed by A).\n"], base: ["The start.\n"], right: ["The start.\n","B added this line.\n"]),
          Dyph3::Outcome::Resolved.new(["The end.\n","cats\n","dogs\n","pigs\n","cows\n","chickens"])
        ]
      }

      it "should not explode" do
        res = Dyph3::Differ.merge(left, base, right, split_function: text_split, join_function: text_join, current_differ: current_differ )
        expect(res.joined_results).to eq expected_result
      end

      it "should not be conflicted when not conflicted" do
        result = Dyph3::Differ.merge(left, base, left, split_function: text_split, join_function: text_join, current_differ: current_differ)
        expect(result.joined_results).to eq left
      end

      it "should not be conflicted with the same text" do
        result = Dyph3::Differ.merge(left, left, left, split_function: text_split, join_function: text_join, current_differ: current_differ)
        expect(result.joined_results).to eq left
      end

      it "should not be conflicted when not conflicted" do
        result = Dyph3::Differ.merge(base, base, base, split_function: text_split, join_function: text_join, current_differ: current_differ)
        expect(result.joined_results).to eq base
      end

      # issue adding \n to the beginning and end of a line
      it "should handle one side unchanged" do
        left = "19275-129 ajkslkf"
        base = "Article title"
        right = "Article title"

        result = Dyph3::Differ.merge(left, base, right, split_function: text_split, join_function: text_join, current_differ: current_differ)
        expect(result.joined_results).to eq left
      end

      it "should handle one side unchanged" do
        left = "This is a big change\nArticle title"
        base = "Article title"
        right = "Article title"

        result = Dyph3::Differ.merge(left, base, right, split_function: text_split, join_function: text_join, current_differ: current_differ)
        expect(result.joined_results).to eq left
      end

      it "should handle empty strings" do
        result = Dyph3::Differ.merge("", "", "", split_function: text_split, join_function: text_join, current_differ: current_differ)
        expect(result.joined_results).to eq ""
      end

      it "should handle null inputs" do
        expect{Dyph3::Differ.merge(nil, nil, nil)}.to raise_error StandardError
      end

      it "should handle non string inputs" do
        expect{Dyph3::Differ.merge("hi", "hello", 3,split_function: text_split, join_function: text_join,)}.to raise_error StandardError
        expect{Dyph3::Differ.merge("hi", {hi: "there"}, 3,split_function: text_split, join_function: text_join,)}.to raise_error StandardError
      end
    end

    describe 'testing trailing newlines' do
      trailing = "hi\nthis is text\n"
      non_trailing = "hi\nthis is text"
      it 'should not have a trailing newline where expected' do
        result1 = Dyph3::Differ.merge(non_trailing, non_trailing, non_trailing, split_function: text_split, join_function: text_join,)
        expect(result1.joined_results[-1]).to_not eq("\n")

        result2 = Dyph3::Differ.merge(non_trailing, trailing, non_trailing, split_function: text_split, join_function: text_join,)
        expect(result2.joined_results[-1]).to_not eq("\n")

        result3 = Dyph3::Differ.merge(non_trailing, trailing, trailing, split_function: text_split, join_function: text_join,)
        expect(result3.joined_results[-1]).to_not eq("\n")

        result4 = Dyph3::Differ.merge(trailing, trailing, non_trailing, split_function: text_split, join_function: text_join,)
        expect(result4.joined_results[-1]).to_not eq("\n")
      end

      it 'should have a trailing newline where expected' do
        result1 = Dyph3::Differ.merge(non_trailing, non_trailing, trailing, split_function: text_split, join_function: text_join,)
        expect(result1.joined_results).to eq(trailing)
        expect(result1.joined_results[-1]).to eq("\n")

        result2 = Dyph3::Differ.merge(trailing, non_trailing, non_trailing, split_function: text_split, join_function: text_join,)
        expect(result2.joined_results[-1]).to eq("\n")

        result3 = Dyph3::Differ.merge(trailing, non_trailing, trailing, split_function: text_split, join_function: text_join,)
        expect(result3.joined_results[-1]).to eq("\n")

        result4 = Dyph3::Differ.merge(trailing, trailing, trailing, split_function: text_split, join_function: text_join,)
        expect(result4.joined_results[-1]).to eq("\n")

      end

      it "should work even when there is whitespace at the beginning of lines and both sides change base" do
        base  = "\n<p>\n Some stuffi\nAnd another line here\n</p>\n"
        left  = "\n<p>\nSome stuff\nAdded a line here\nAnd another line here\n</p>\n"
        right = "\n<p>\nSome stuff\nAnd another line here\n</p>\nMore stuff here\n"

        result = Dyph3::Differ.merge(left, base, right, split_function: text_split, join_function: text_join,)
        expect(result.joined_results).to eq ['', '<p>', 'Some stuff', 'Added a line here', 'And another line here', '</p>', 'More stuff here', ''].join("\n")
      end

      it "spot a conflict when left right and base don't agree" do
        base = "Some stuff:\n<p>\nThis calculation can</p>\n\n\n</p>\n"
        left = "Some stuff:\n<figref id=\"30835\"></figref>\n<p>\nThis calculation can</p>\n</p>\n"
        right = "Some stuff:\n<p>\nThis calculation can</p>\n<figref id=\"30836\"></figref>\n</p>\n"
        expected_result = [
          Dyph3::Outcome::Resolved.new("Some stuff:\n<figref id=\"30835\"></figref>\n<p>\nThis calculation can</p>\n"),
          Dyph3::Outcome::Conflicted.new(
            left: "",
            right: "<figref id=\"30836\"></figref>\n",
            base: "\n\n"
          ),
          Dyph3::Outcome::Resolved.new("</p>\n")
        ]
        merged_text = Dyph3::Differ.merge(left, base, right, split_function: text_split, join_function: text_join, conflict_function: conflict_function)
        expect(merged_text.joined_results).to eql expected_result
      end
    end
  end
end