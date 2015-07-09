require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }

  # [Dyph3::TwoWayDiffers::ResigDiff, Dyph3::TwoWayDiffers::HeckelDiff].each do |current_differ|
  [Dyph3::TwoWayDiffers::OriginalHeckelDiff].each do |current_differ|
    describe current_differ do
      describe "both moves and inserts" do
        it "should handle when base and left match" do
          left =  "ants bears cat dog".split
          base =  "ants bears cat dog".split
          right =  "ants elephant cat bears dog".split
          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
          expect(result[0]).to eq right
          expect(result[1]).to be false
        end

        it "should handle when base and right match" do
          right =  "ants bears cat dog".split
          base =  "ants bears cat dog".split
          left =  "ants elephant cat bears dog".split
          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
          expect(result[0]).to eq left
          expect(result[1]).to be false
        end

        it "should handle when base and left match" do
          left =  "ants bears cat".split
          base =  "ants bears cat".split
          right =  "ants elephant cat bears".split
          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
          expect(result[0]).to eq right
          expect(result[1]).to be false
        end

        it "should handle when the first elements are switched and an insert at the end" do
          left =  "ants bears cat".split
          base =  "ants bears cat".split
          right =  "bears ants cat elephant".split
          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
          expect(result[0]).to eq right
          expect(result[1]).to be false
        end

        it "should handle when the last elements are switched and an insert at the beginning" do
          left =  "ants bears cat".split
          base =  "ants bears cat".split
          right =  "elephant ants cat bears".split
          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
          expect(result[0]).to eq right
          expect(result[1]).to be false
        end

        it "should handle when all three are different" do
          left =  "ant bear cat monkey goat".split
          base =  "ant bear cat monkey".split
          right = "ant cat bear dog elephant monkey goat".split
          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity , join_function: identity, current_differ: current_differ)
          expect(result[0]).to eq right
          expect(result[1]).to be false
        end

        it "should handle this really complex real-world case" do
          left = [ "common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]
          base = [ "common_id_1", "common_h2_open", "left_word_1", "common_word_1", "common_h2_close", "common_id_1_close", "left_id_1", "common_p_open", "common_phrase_1", "left_word_2", "common_word_6", "left_word_3", "common_word_1", "left_word_4", "common_p_close", "left_id_close" ]
          right = [ "right_id_1", "common_h2_open", "right_word_1", "common_word_1", "common_h2_close", "right_id_1_close", "common_id_1", "common_p_open", "common_phrase_1", "common_p_close", "common_id_1_close" ]

          result = Dyph3::Differ.merge_text(left, base, right, split_function: identity, join_function: identity, current_differ: current_differ)

          expect(result[0]).to eq right
          expect(result[1]).to be false
        end
      end

      describe "test split" do
        let(:base) { [:a, :b, :c] }
        let(:left) { [:a, :b, :c] }
        let(:right) { [:a, :v, :c] }
        

        let(:merged_array) do
           Dyph3::Differ.merge_text(left, base, right, split_function: identity, join_function: identity, current_differ: current_differ )
        end

        it "should have merged successuffly" do
          expect(merged_array[0]).to eq right
        end
      end

      describe "test split" do
        let(:base) { Fish.new(:salmon) }
        let(:left) { Fish.new(:salmon) }
        let(:right) { Fish.new(:pollock) }

        let(:merged_array) do
          Dyph3::Differ.merge_text(left, base, right )
        end

        it "should have merged successfully" do
          expect(merged_array[0]).to eq right
        end
      end
      describe "test conflict function" do
        let(:base) { Fish.new(:salmon) }
        let(:left) { Fish.new(:trout) }
        let(:right) { Fish.new(:pollock) }

        let!(:merged_array) do
          Dyph3::Differ.merge_text(left, base, right )
        end

        it "should have merged successfully" do
          expect(merged_array.last.last[:conflict_custom]).to eq [:tuna]
        end
      end

      describe "test" do
        let(:base) { "This is the baseline.\nThe start.\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

        let(:left) { "This is the baseline.\nThe start (changed by A).\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

        let(:right) {"This is the baseline.\nThe start.\nB added this line.\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

        let(:expected_result){[
          base,
          true,
          [{type: :non_conflict, text: "This is the baseline.\n"},
          {type: :conflict, ours: "The start (changed by A).\n", base: "The start.\n", theirs: "The start.\nB added this line.\n"},
          {type: :non_conflict, text: "The end.\ncats\ndogs\npigs\ncows\nchickens"}]]
        }

        it "should not explode" do
          res = Dyph3::Differ.merge_text(left, base, right )
          expect(res).to eq expected_result
        end

        it "should not be conflicted when not conflicted" do
          result = Dyph3::Differ.merge_text(left, base, left)
          expecting = left
          expect(result).to eq [left, false, [{type: :non_conflict, text: left}]]
        end

        it "should not be conflicted with the same text" do
          result = Dyph3::Differ.merge_text(left, left, left)
          expecting = left
          expect(result).to eq [left, false, [{type: :non_conflict, text: left}]]
        end

        it "should not be conflicted when not conflicted" do
          result = Dyph3::Differ.merge_text(base, base, base)
          expect(result).to eq [base, false, [{type: :non_conflict, text: base}]]
        end

        # issue adding \n to the beginning and end of a line
        it "should handle one side unchanged" do
          left = "19275-129 ajkslkf"
          base = "Article title"
          right = "Article title"

          result = Dyph3::Differ.merge_text(left, base, right)
          expect(result).to eq [left, false, [{type: :non_conflict, text: left}]]
        end

        it "should handle one side unchanged" do
          left = "This is a big change\nArticle title"
          base = "Article title"
          right = "Article title"

          result = Dyph3::Differ.merge_text(left, base, right)
          expect(result).to eq [left, false, [{type: :non_conflict, text: left}]]
        end

        it "should handle empty strings" do
          result = Dyph3::Differ.merge_text("", "", "")
          expect(result).to eq ["", false, [{type: :non_conflict, text: ""}]]
        end

        it "should handle null inputs" do
          expect{Dyph3::Differ.merge_text(nil, nil, nil)}.to raise_error
        end

        it "should handle non string inputs" do
          expect{Dyph3::Differ.merge_text("hi", "hello", 3)}.to raise_error
          expect{Dyph3::Differ.merge_text("hi", {hi: "there"}, 3)}.to raise_error
        end
      end

      describe 'should have conflict' do
        left = """\n<h2>\nThis is cool.\n</h2>\n<p>\nHi I'm a paragraph.\nI'm another sentence in the paragraph.\n</p>"""
        right = """\n<h2>\nThis is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n</p>"""
        base = """\n<h2>\nThis is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n</p>"""
        expected_result = [
          base,
          true,
          [ {type: :non_conflict, text: "\n<h2>\nThis is cool.\n</h2>\n<p>\n"},
            {type: :conflict, ours: "Hi I'm a paragraph.\nI'm another sentence in the paragraph.\n", 
                              theirs: " Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n",
                              base: " Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n"},
            {type: :non_conflict, text: "</p>"}]]

        it "should produce a conflict" do
          result = Dyph3::Differ.merge_text(left, base, right)
          expect(result.length).to be > 0
          expect(result[0]).to eq expected_result[0]
          expect(result[1]).to eq expected_result[1]
          expect(result[2]).to eq expected_result[2]
        end
      end

      describe 'testing multiple types of conflicts' do
        ours = ""
        theirs = ""
        base = "this is some text\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
        it 'should have a conflict in the first line' do
          ours = "THIS IS some text\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
          theirs = "THIS IS SOME TEXT\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
          expected_result = [
            base,
            true,
            [ {type: :conflict, ours: "THIS IS some text\n", base: "this is some text\n", theirs: "THIS IS SOME TEXT\n"},
              {type: :non_conflict, text: "another line of text\none more good line\nthats about it now\nthis is the last line\n"}]]
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expect(result).to eq(expected_result)
        end
        it 'should have a conflict in the last line' do
          ours = "this is some text\nanother line of text\none more good line\nthats about it NOW\nTHIS is the last line\n"
          theirs="this is some text\nanother line of text\none more good line\nthats about it no\nTHIS is the LAST LINE\n"
          expected_result = [
            base,
            true,
            [ {type: :non_conflict, text: "this is some text\nanother line of text\none more good line\n"},
              {type: :conflict, ours: "thats about it NOW\nTHIS is the last line\n", base: "thats about it now\nthis is the last line\n", theirs: "thats about it no\nTHIS is the LAST LINE\n"}]]
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expect(result).to eq(expected_result)
        end
        it 'should have a single conflict in between non_conflicts' do
          ours = "this is some text\nanother line of text\none more BAD line\nwe inserted a line\nthats about it now\nthis is the last line\n"
          theirs = "this is some text\nanother line of text\none more GREAT line\nthey inserted a line\nthats about it now\nthis is the last line\n"
          expected_result = [
            base,
            true,
            [ {type: :non_conflict, text: "this is some text\nanother line of text\n"},
              {type: :conflict, ours: "one more BAD line\nwe inserted a line\n", base: "one more good line\n", theirs: "one more GREAT line\nthey inserted a line\n"},
              {type: :non_conflict, text: "thats about it now\nthis is the last line\n"}]]
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expect(result).to eq(expected_result)
        end
        it 'should handle overlapping conflicts' do
          ours   = "this is some text\nanother LINE of text\none more GREAT line\nthats about it now\nthis is the last line\n"
          theirs = "this is some text\nanother line of text\none more GOOD line\nthats ABOUT it now\nthis is the last line\n"
          expected_result = [
            base,
            true,
            [ {type: :non_conflict, text: "this is some text\n"},
              {type: :conflict, ours: "another LINE of text\none more GREAT line\nthats about it now\n", 
                                base: "another line of text\none more good line\nthats about it now\n", 
                                theirs: "another line of text\none more GOOD line\nthats ABOUT it now\n"},
              {type: :non_conflict, text: "this is the last line\n"}]]
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expect(result).to eq(expected_result)
          expected_result_reversed = [
            base,
            true,
            [ {type: :non_conflict, text: "this is some text\n"},
              {type: :conflict, theirs: "another LINE of text\none more GREAT line\nthats about it now\n", 
                                base: "another line of text\none more good line\nthats about it now\n", 
                                ours: "another line of text\none more GOOD line\nthats ABOUT it now\n"},
              {type: :non_conflict, text: "this is the last line\n"}]]
          result_reversed = Dyph3::Differ.merge_text(theirs, base, ours)
          expect(result_reversed).to eq(expected_result_reversed)
        end

        it 'should handle a conflict, non_conflict, conflict pattern' do
          our_text = "A\nB\nC\n"
          their_text = "a\nB\nc\n"
          base_text = "aa\nB\ncc\n"
          result = Dyph3::Differ.merge_text(our_text, base_text, their_text)
          expected_result = [
            base_text, 
            true, 
            [{type: :conflict, ours: "A\n", base: "aa\n", theirs: "a\n" },
            {type: :non_conflict, text: "B\n"},
            {type: :conflict, ours: "C\n", base: "cc\n", theirs: "c\n" }]]
          expect(result).to eq (expected_result)
        end

        it 'should handle periodic conflicts' do
          base   += "woohoo!\n"
          ours    = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats about IT now\nthis is the last line\nWOOHOO!\n"
          theirs  = "this is some text\nanother LINE of text\none more good line\nthats ABOUT it now\nthis is the last line\nwooHOO!\n"
          expected_result = [base, true, 
            [{type: :non_conflict, text: "this is some text\n"},
             {type: :conflict, ours:"ANOTHER LINE OF TEXT\n",  base: "another line of text\n", theirs:"another LINE of text\n"},
             {type: :non_conflict, text: "one more good line\n"},
             {type: :conflict, ours:"thats about IT now\n", base:"thats about it now\n", theirs: "thats ABOUT it now\n"},
             {type: :non_conflict, text: "this is the last line\n"},
             {type: :conflict, ours: "WOOHOO!\n", base:"woohoo!\n", theirs:"wooHOO!\n"}]]
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expect(result).to eq expected_result
        end

        it 'should handle non overlapping changes without conflicts' do
          base            = "this is some text\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
          ours            = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats about it now\nthis is the last line\n"
          theirs          = "this is some text\nanother line of text\none more good line\nthats ABOUT it now\nthis is the last line\n"
          expected_string = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats ABOUT it now\nthis is the last line\n"
          expected_result = [expected_string, false, [{type: :non_conflict, text: expected_string }]]
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expect(result).to eq(expected_result)
        end

        context "both sides deleting, but one side deleting more" do
          it "partial deletion of the first half of a line" do
            base            = "this is some text\nanother line of text"
            ours            = "another line of text"
            theirs          = "some text\nanother line of text"

            expected_result = ["this is some text\nanother line of text",
              true,
              [{:type=>:conflict, :ours=>"", :base=>"this is some text\n", :theirs=>"some text\n"},
              {:type=>:non_conflict, :text=>"another line of text"}]
            ]
            result = Dyph3::Differ.merge_text(ours, base, theirs)
            expect(result).to eq(expected_result)
          end

          it "partial deletion of a middle line" do
            base            = "this is the first line\nthis is some text\nanother line of text"
            ours            = "this is the first line\nanother line of text"
            theirs          = "this is the first line\nthis is\nanother line of text"
         #   expected_string = "this is the first line\nanother line of text"
            expected_result = ["this is the first line\nthis is some text\nanother line of text",
              true,
              [{:type=>:non_conflict, :text=>"this is the first line\n"},
               {:type=>:conflict,
                :ours=>"",
                :base=>"this is some text\n",
                :theirs=>"this is\n"},
               {:type=>:non_conflict, :text=>"another line of text"}]]
            result = Dyph3::Differ.merge_text(ours, base, theirs)
            expect(result).to eq(expected_result)
          end
        end

        it 'should handle a creation of two different things' do
          ours = 'apple'
          base = ''
          theirs = 'apricot'
          result = Dyph3::Differ.merge_text(ours, base, theirs)
          expected_result = ["", true, [{type: :conflict, ours: "apple", base: "", theirs: "apricot"}]]
          expect(result).to eq(expected_result)
        end
      end

      describe 'testing trailing newlines' do
        trailing = "hi\nthis is text\n"
        non_trailing = "hi\nthis is text"
        it 'should not have a trailing newline where expected' do
          result1 = Dyph3::Differ.merge_text(non_trailing, non_trailing, non_trailing)
          expect(result1[0][-1]).to_not eq("\n")
          
          result2 = Dyph3::Differ.merge_text(non_trailing, trailing, non_trailing)
          expect(result2[0][-1]).to_not eq("\n")
          
          result3 = Dyph3::Differ.merge_text(non_trailing, trailing, trailing)
          expect(result3[0][-1]).to_not eq("\n")
          
          result4 = Dyph3::Differ.merge_text(trailing, trailing, non_trailing)
          expect(result4[0][-1]).to_not eq("\n")
        end

        it 'should have a trailing newline where expected' do
          result1 = Dyph3::Differ.merge_text(non_trailing, non_trailing, trailing)
          expect(result1[0]).to eq(trailing)
          expect(result1[0][-1]).to eq("\n")

          result2 = Dyph3::Differ.merge_text(trailing, non_trailing, non_trailing)
          expect(result2[0][-1]).to eq("\n")

          result3 = Dyph3::Differ.merge_text(trailing, non_trailing, trailing)
          expect(result3[0][-1]).to eq("\n")

          result4 = Dyph3::Differ.merge_text(trailing, trailing, trailing)
          expect(result4[0][-1]).to eq("\n")

        end

        it "should work even when there is whitespace at the beginning of lines and both sides change base" do
          base  = "\n<p>\n Some stuffi\nAnd another line here\n</p>\n"
          left  = "\n<p>\nSome stuff\nAdded a line here\nAnd another line here\n</p>\n"
          right = "\n<p>\nSome stuff\nAnd another line here\n</p>\nMore stuff here\n"

          result = Dyph3::Differ.merge_text(left, base, right)
          expect(result[0]).to eq ['', '<p>', 'Some stuff', 'Added a line here', 'And another line here', '</p>', 'More stuff here', ''].join("\n")
        end

        it "spot a conflict when left right and base don't agree" do
          base = "Some stuff:\n<p>\nThis calculation can</p>\n\n\n</p>\n"
          left = "Some stuff:\n<figref id=\"30835\"></figref>\n<p>\nThis calculation can</p>\n</p>\n"
          right = "Some stuff:\n<p>\nThis calculation can</p>\n<figref id=\"30836\"></figref>\n</p>\n"
          expected_result = [
            base,
            true,
          [ {type: :non_conflict, text: "Some stuff:\n<figref id=\"30835\"></figref>\n<p>\nThis calculation can</p>\n"},
            {type: :conflict, ours: "",
                              theirs: "<figref id=\"30836\"></figref>\n",
                              base: "\n\n"},
            {type: :non_conflict, text: "</p>\n"}]]

            expect(Dyph3::Differ.merge_text(left, base, right)).to eql expected_result
        end
      end
    end
  end

  # note: this seems to be using the Resig differ only
  describe ".merge_two_way_diff" do
    it "show all no changes" do
      t1 = "a b c d".split
      diff = Dyph3::Differ.merge_two_way_diff(t1, t1)
      expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange]
    end


    it "should show an add" do
      t1 = "a b c d".split
      t2 = "a b c d e".split
      diff = Dyph3::Differ.merge_two_way_diff(t1, t2)
      expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Add]
    end

    it "should show a delete" do
      t1 = "a b c d".split
      t2 = "a b c".split
      diff = Dyph3::Differ.merge_two_way_diff(t1, t2)
      expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete]
    end

    it "should show a change" do
      t1 = "a b c d".split
      t2 = "a b z d".split
      diff = Dyph3::Differ.merge_two_way_diff(t1, t2)
      expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete, Dyph3::Add, Dyph3::NoChange]
    end
  end
end
