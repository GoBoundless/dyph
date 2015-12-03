require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }
  two_way_differs.each do |current_differ|
    describe "both moves and inserts" do
      it "should handle when base and left match" do
        left =  "ants bears cat dog".split
        base =  "ants bears cat dog".split
        right =  "ants elephant cat bears dog".split
        merge_result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
        expect(merge_result.joined_results).to eq right
        expect(merge_result.success?).to be true
      end

      it "should handle when base and right match" do
        right =  "ants bears cat dog".split
        base =  "ants bears cat dog".split
        left =  "ants elephant cat bears dog".split
        result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
        expect(result.joined_results).to eq left
        expect(result.success?).to be true
      end

      it "should handle when base and left match" do
        left =  "ants bears cat".split
        base =  "ants bears cat".split
        right =  "ants elephant cat bears".split
        result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
        expect(result.joined_results).to eq right
        expect(result.success?).to be true
      end

      it "should handle when the first elements are switched and an insert at the end" do
        left =  "ants bears cat".split
        base =  "ants bears cat".split
        right =  "bears ants cat elephant".split
        result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
        expect(result.joined_results).to eq right
        expect(result.success?).to be true
      end

      it "should handle when the last elements are switched and an insert at the beginning" do
        left =  "ants bears cat".split
        base =  "ants bears cat".split
        right =  "elephant ants cat bears".split
        result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
        expect(result.joined_results).to eq right
        expect(result.success?).to be true
      end

      it "should handle when all three are different" do
        left =  "ant bear cat monkey goat".split
        base =  "ant bear cat monkey".split
        right = "ant cat bear dog elephant monkey goat".split
        result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
        expect(result.joined_results).to eq right
        expect(result.success?).to be true
      end

      it "should handle this really complex real-world case" do
        left = [ "common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]
        base = [ "common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]
        right = [ "right_id_1", "common_h2_open", "right_word_1", "common_word_1", "common_h2_close", "right_id_1_close", "common_id_1", "common_p_open", "common_phrase_1", "common_p_close", "common_id_1_close" ]

        result = Dyph3::Differ.merge_text(left, base, right, split_function: identity, join_function: identity, current_differ: current_differ)

        expect(result.joined_results).to eq right
        expect(result.success?).to be true
      end
    end
  end
end