require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }
  #conflict function just applys a join on each outcome item
  let(:conflict_function) { ->(xs) { xs.map { |x| x.apply(->(array) {array.join})}} }
  # [Dyph3::TwoWayDiffers::ResigDiff, Dyph3::TwoWayDiffers::HeckelDiff].each do |current_differ|
  two_way_differs.each do |current_differ|
    describe 'should have conflict' do
      left = """\n<h2>\nThis is cool.\n</h2>\n<p>\nHi I'm a paragraph.\nI'm another sentence in the paragraph.\n</p>"""
      right = """\n<h2>\nThis is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n</p>"""
      base = """\n<h2>\nThis is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n</p>"""
      expected_result =
        [ Dyph3::Outcome::Resolved.new("\n<h2>\nThis is cool.\n</h2>\n<p>\n"),
          Dyph3::Outcome::Conflicted.new(left: "Hi I'm a paragraph.\nI'm another sentence in the paragraph.\n",
                            right: " Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n",
                            base: " Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n"),
          Dyph3::Outcome::Resolved.new("</p>")]

      it "should produce a conflict" do
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function )
        expect(result.joined_results).to eq expected_result
        expect(result.conflict?).to eq true
      end
    end

    describe 'testing multiple types of conflicts' do
      left = ""
      right = ""
      base = "this is some text\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
      it 'should have a conflict in the first line' do
        left = "THIS IS some text\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
        right = "THIS IS SOME TEXT\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
        expected_result = [
            Dyph3::Outcome::Conflicted.new(left: "THIS IS some text\n", base: "this is some text\n", right: "THIS IS SOME TEXT\n"),
            Dyph3::Outcome::Resolved.new("another line of text\none more good line\nthats about it now\nthis is the last line\n")]
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expect(result.joined_results).to eq(expected_result)
        expect(result.conflict?).to eq(true)
      end

      it 'should have a conflict in the last line' do
        left = "this is some text\nanother line of text\none more good line\nthats about it NOW\nTHIS is the last line\n"
        right="this is some text\nanother line of text\none more good line\nthats about it no\nTHIS is the LAST LINE\n"
        expected_result = [
            Dyph3::Outcome::Resolved.new("this is some text\nanother line of text\none more good line\n"),
            Dyph3::Outcome::Conflicted.new(left: "thats about it NOW\nTHIS is the last line\n", base: "thats about it now\nthis is the last line\n", right: "thats about it no\nTHIS is the LAST LINE\n")
        ]
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expect(result.joined_results).to eq(expected_result)
        expect(result.conflict?).to eq(true)

      end
      it 'should have a single conflict in between non_conflicts' do
        left = "this is some text\nanother line of text\none more BAD line\nwe inserted a line\nthats about it now\nthis is the last line\n"
        right = "this is some text\nanother line of text\none more GREAT line\nthey inserted a line\nthats about it now\nthis is the last line\n"
        expected_result = [
          Dyph3::Outcome::Resolved.new("this is some text\nanother line of text\n"),
          Dyph3::Outcome::Conflicted.new(left: "one more BAD line\nwe inserted a line\n", base: "one more good line\n", right: "one more GREAT line\nthey inserted a line\n"),
          Dyph3::Outcome::Resolved.new("thats about it now\nthis is the last line\n")
        ]
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expect(result.joined_results).to eq(expected_result)
        expect(result.conflict?).to eq(true)
      end

      it 'should handle overlapping conflicts' do
        left   = "this is some text\nanother LINE of text\none more GREAT line\nthats about it now\nthis is the last line\n"
        right = "this is some text\nanother line of text\none more GOOD line\nthats ABOUT it now\nthis is the last line\n"
        expected_result =
          [ 
            Dyph3::Outcome::Resolved.new("this is some text\n"),
            Dyph3::Outcome::Conflicted.new(
              left: "another LINE of text\none more GREAT line\nthats about it now\n", 
              base: "another line of text\none more good line\nthats about it now\n", 
              right: "another line of text\none more GOOD line\nthats ABOUT it now\n"),
            Dyph3::Outcome::Resolved.new("this is the last line\n")
          ]

        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expect(result.joined_results).to eq(expected_result)

        expected_result_reversed = [
          Dyph3::Outcome::Resolved.new("this is some text\n"),
          Dyph3::Outcome::Conflicted.new(right: "another LINE of text\none more GREAT line\nthats about it now\n", 
                            base: "another line of text\none more good line\nthats about it now\n", 
                            left: "another line of text\none more GOOD line\nthats ABOUT it now\n"),
          Dyph3::Outcome::Resolved.new("this is the last line\n")
        ]
        result_reversed = Dyph3::Differ.merge_text(right, base, left, conflict_function: conflict_function)
        expect(result_reversed.joined_results).to eq(expected_result_reversed)
      end

      it 'should handle a conflict, non_conflict, conflict pattern' do
        our_text = "A\nB\nC\n"
        their_text = "a\nB\nc\n"
        base_text = "aa\nB\ncc\n"
        result = Dyph3::Differ.merge_text(our_text, base_text, their_text, conflict_function: conflict_function)
        expected_result = [
          Dyph3::Outcome::Conflicted.new(left: "A\n", base: "aa\n", right: "a\n"),
          Dyph3::Outcome::Resolved.new("B\n"),
          Dyph3::Outcome::Conflicted.new(left: "C\n", base: "cc\n", right: "c\n")
        ]
        expect(result.joined_results).to eq (expected_result)
      end

      it 'should handle periodic conflicts' do
        base   += "woohoo!\n"
        left    = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats about IT now\nthis is the last line\nWOOHOO!\n"
        right  = "this is some text\nanother LINE of text\none more good line\nthats ABOUT it now\nthis is the last line\nwooHOO!\n"
        expected_result = [
          Dyph3::Outcome::Resolved.new("this is some text\n"),
          Dyph3::Outcome::Conflicted.new(left:"ANOTHER LINE OF TEXT\n",  base: "another line of text\n", right:"another LINE of text\n"),
          Dyph3::Outcome::Resolved.new("one more good line\n"),
          Dyph3::Outcome::Conflicted.new(left:"thats about IT now\n", base:"thats about it now\n", right: "thats ABOUT it now\n"),
          Dyph3::Outcome::Resolved.new("this is the last line\n"),
          Dyph3::Outcome::Conflicted.new(left: "WOOHOO!\n", base:"woohoo!\n", right:"wooHOO!\n")
        ]
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expect(result.joined_results).to eq expected_result
        expect(result.conflict?).to eq true
      end

      it 'should handle non overlapping changes without conflicts' do
        base  = "this is some text\nanother line of text\none more good line\nthats about it now\nthis is the last line\n"
        left  = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats about it now\nthis is the last line\n"
        right = "this is some text\nanother line of text\none more good line\nthats ABOUT it now\nthis is the last line\n"
        expected_string = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats ABOUT it now\nthis is the last line\n"
        expected_result = expected_string
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expect(result.joined_results).to eq(expected_result)
        expect(result.success?).to eq(true)
      end

      context "both sides deleting, but one side deleting more" do
        it "partial deletion of the first half of a line" do
          base  = "this is some text\nanother line of text"
          left  = "another line of text"
          right = "some text\nanother line of text"

          expected_result = [
             Dyph3::Outcome::Conflicted.new(:left=>"", :base=>"this is some text\n", :right=>"some text\n"),
             Dyph3::Outcome::Resolved.new("another line of text")
          ]
          result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
          expect(result.joined_results).to eq(expected_result)
          expect(result.conflict?).to eq(true)
        end

        it "partial deletion of a middle line" do
          base  = "this is the first line\nthis is some text\nanother line of text"
          left  = "this is the first line\nanother line of text"
          right = "this is the first line\nthis is\nanother line of text"
       #   expected_string = "this is the first line\nanother line of text"
          expected_result = [
             Dyph3::Outcome::Resolved.new("this is the first line\n"),
             Dyph3::Outcome::Conflicted.new(
                left: "",
                base: "this is some text\n",
                right: "this is\n"),
             Dyph3::Outcome::Resolved.new("another line of text")
          ]
          result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
          expect(result.joined_results).to eq(expected_result)
        end
      end

      it 'should handle a creation of two different things' do
        left = 'apple'
        base = ''
        right = 'apricot'
        result = Dyph3::Differ.merge_text(left, base, right, conflict_function: conflict_function)
        expected_result = [ Dyph3::Outcome::Conflicted.new(left: "apple", base: "", right: "apricot")]
        expect(result.joined_results).to eq(expected_result)
      end
    end
  end
end