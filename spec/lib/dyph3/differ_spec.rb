require "dyph3"
require "pry"
require "awesome_print"

describe Dyph3::Differ do
  describe "test" do
    let(:base) { "This is the baseline.\nThe start.\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

    let(:left) { "This is the baseline.\nThe start (changed by A).\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

    let(:right) {"This is the baseline.\nThe start.\nB added this line.\nThe end.\ncats\ndogs\npigs\ncows\nchickens"}

    let(:expected_result){[
      {type: :non_conflict, text: "This is the baseline.\n"},
      {type: :conflict, ours: "The start (changed by A).\n", base: "The start.\n", theirs: "The start.\nB added this line.\n"},
      {type: :non_conflict, text: "The end.\ncats\ndogs\npigs\ncows\nchickens"}
    ]}

    it "should not explode" do
      res = Dyph3::Differ.merge_text(left, base, right)
      expect(res).to eq expected_result
    end

    it "should not be conflicted when not conflicted" do
      result = Dyph3::Differ.merge_text(left, base, left)
      expecting = left
      expect(result).to eq expecting
    end

    it "should not be conflicted when not conflicted" do
      result = Dyph3::Differ.merge_text(base, base, base)
      expect(result).to eq base
    end

    # issue adding \n to the beginning and end of a line
    it "should handle one side unchanged" do
      left = "19275-129 ajkslkf"
      base = "Article title"
      right = "Article title"

      result = Dyph3::Differ.merge_text(left, base, right)
      expect(result).to eq(left)
    end

    it "should handle one side unchanged" do
      left = "This is a big change\nArticle title"
      base = "Article title"
      right = "Article title"

      result = Dyph3::Differ.merge_text(left, base, right)
      expect(result).to eq(left)
    end
  end

  describe 'should have conflict' do
    left = """\n<h2>\nThis is cool.\n</h2>\n<p>\nHi I'm a paragraph.\nI'm another sentence in the paragraph.\n</p>"""
    right = """\n<h2>\nThis is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n</p>"""
    base = """\n<h2>\nThis is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n</p>"""
    expected_result = [
      {type: :non_conflict, text: "\n<h2>\nThis is cool.\n</h2>\n<p>\n"},
      {type: :conflict, ours: "Hi I'm a paragraph.\nI'm another sentence in the paragraph.\n", 
                        theirs: " Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n",
                        base: " Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n"},
      {type: :non_conflict, text: "</p>"}                  
    ]

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
        {type: :conflict, ours: "THIS IS some text\n", base: "this is some text\n", theirs: "THIS IS SOME TEXT\n"},
        {type: :non_conflict, text: "another line of text\none more good line\nthats about it now\nthis is the last line\n"}]
      result = Dyph3::Differ.merge_text(ours, base, theirs)
      expect(result).to eq(expected_result)
    end
    it 'should have a conflict in the last line' do
      ours = "this is some text\nanother line of text\none more good line\nthats about it NOW\nTHIS is the last line\n"
      theirs="this is some text\nanother line of text\none more good line\nthats about it no\nTHIS is the LAST LINE\n"
      expected_result = [
        {type: :non_conflict, text: "this is some text\nanother line of text\none more good line\n"},
        {type: :conflict, ours: "thats about it NOW\nTHIS is the last line\n", base: "thats about it now\nthis is the last line\n", theirs: "thats about it no\nTHIS is the LAST LINE\n"}]
      result = Dyph3::Differ.merge_text(ours, base, theirs)
      expect(result).to eq(expected_result)
    end
    it 'should have a single conflict in between non_conflicts' do
      ours = "this is some text\nanother line of text\none more BAD line\nwe inserted a line\nthats about it now\nthis is the last line\n"
      theirs = "this is some text\nanother line of text\none more GREAT line\nthey inserted a line\nthats about it now\nthis is the last line\n"
      expected_result = [
        {type: :non_conflict, text: "this is some text\nanother line of text\n"},
        {type: :conflict, ours: "one more BAD line\nwe inserted a line\n", base: "one more good line\n", theirs: "one more GREAT line\nthey inserted a line\n"},
        {type: :non_conflict, text: "thats about it now\nthis is the last line\n"}]
      result = Dyph3::Differ.merge_text(ours, base, theirs)
      expect(result).to eq(expected_result)
    end
    it 'should handle overlapping conflicts' do
      ours = "this is some text\nanother LINE of text\none more GREAT line\nthats about it now\nthis is the last line\n"
      theirs = "this is some text\nanother line of text\none more GOOD line\nthats ABOUT it now\nthis is the last line\n"
      expected_result = [
        {type: :non_conflict, text: "this is some text\n"},
        {type: :conflict, ours: "another LINE of text\none more GREAT line\nthats about it now\n", 
                          base: "another line of text\none more good line\nthats about it now\n", 
                          theirs: "another line of text\none more GOOD line\nthats ABOUT it now\n"},
        {type: :non_conflict, text: "this is the last line\n"}]
      result = Dyph3::Differ.merge_text(ours, base, theirs)
      expect(result).to eq(expected_result)
      expected_result_reversed = [
        {type: :non_conflict, text: "this is some text\n"},
        {type: :conflict, theirs: "another LINE of text\none more GREAT line\nthats about it now\n", 
                          base: "another line of text\none more good line\nthats about it now\n", 
                          ours: "another line of text\none more GOOD line\nthats ABOUT it now\n"},
        {type: :non_conflict, text: "this is the last line\n"}]
      result_reversed = Dyph3::Differ.merge_text(theirs, base, ours)
      expect(result_reversed).to eq(expected_result_reversed)
    end
    it 'should handle non overlapping changes without conflicts' do
      ours = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats about it now\nthis is the last line\n"
      theirs = "this is some text\nanother line of text\none more good line\nthats ABOUT it now\nthis is the last line\n"
      expected_result = "this is some text\nANOTHER LINE OF TEXT\none more good line\nthats ABOUT it now\nthis is the last line\n"
      result = Dyph3::Differ.merge_text(ours, base, theirs)
      expect(result).to eq(expected_result)
    end
  end

  describe 'testing trailing newlines' do
    trailing = "hi\nthis is text\n"
    non_trailing = "hi\nthis is text"
    it 'should not have a trailing newline where expected' do
      result1 = Dyph3::Differ.merge_text(non_trailing, non_trailing, non_trailing)
      expect(result1[-1]).to_not eq("\n")
      
      result2 = Dyph3::Differ.merge_text(non_trailing, trailing, non_trailing)
      expect(result2[-1]).to_not eq("\n")
      
      result3 = Dyph3::Differ.merge_text(non_trailing, trailing, trailing)
      expect(result3[-1]).to_not eq("\n")
      
      result4 = Dyph3::Differ.merge_text(trailing, trailing, non_trailing)
      expect(result4[-1]).to_not eq("\n")
    end

    it 'should have a trailing newline where expected' do
      result1 = Dyph3::Differ.merge_text(non_trailing, non_trailing, trailing)
      expect(result1).to eq(trailing)
      expect(result1[-1]).to eq("\n")

      result2 = Dyph3::Differ.merge_text(trailing, non_trailing, non_trailing)
      expect(result2[-1]).to eq("\n")

      result3 = Dyph3::Differ.merge_text(trailing, non_trailing, trailing)
      expect(result3[-1]).to eq("\n")

      result4 = Dyph3::Differ.merge_text(trailing, trailing, trailing)
      expect(result4[-1]).to eq("\n")
      
    end
  end
end
