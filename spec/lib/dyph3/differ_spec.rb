require "dyph3"
require "pry"
require "awesome_print"

describe Dyph3::Differ do
  describe "test" do
    let(:base) { <<-TEXT
  This is the baseline.
  The start.
  The end.
  cats
  dogs
  pigs
  cows
  chickens
  TEXT
  }

    let(:left) { <<-TEXT
  This is the baseline.
  The start (changed by A).
  The end.
  cats
  dogs
  pigs
  cows
  chickens
  TEXT
  }

    let(:right) { <<-TEXT
  This is the baseline.
  The start.
  B added this line.
  The end.
  cats
  dogs
  pigs
  cows
  chickens
  TEXT
  }

    let(:expected_result) {
      <<-TEXT.rstrip
  This is the baseline.
<<<<<<< start
  The start (changed by A).
|||||||
  The start.
=======
  The start.
  B added this line.
>>>>>>> changed_b
  The end.
  cats
  dogs
  pigs
  cows
  chickens
  TEXT
  }

    it "should not explode" do
      result = Dyph3::Differ.merge_text(left, base, right, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
      expect(result[:conflict]).to eq(1)
      expect(result[:body]).to eq expected_result
    end

    it "should not be conflicted when not conflicted" do
      result = Dyph3::Differ.merge_text(left, base, left, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
      expect(result[:body]).to eq left.rstrip #BUGBUG: differ losing a new line?
      expect(result[:conflict]).to eq(0)
    end

    it "should not be conflicted when not conflicted" do
      result = Dyph3::Differ.merge_text(base, base, base, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
      expect(result[:body]).to eq base.rstrip #BUGBUG: differ losing a new line?
      expect(result[:conflict]).to eq(0)
    end

    it "should allow you to not include the base in the result" do
      expected_result = <<-TEXT.rstrip
  This is the baseline.
<<<<<<< start
  The start (changed by A).
=======
  The start.
  B added this line.
>>>>>>> changed_b
  The end.
  cats
  dogs
  pigs
  cows
  chickens
  TEXT

      result = Dyph3::Differ.merge_text(left, base, right, include_base: false, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
      expect(result[:conflict]).to eq(1)
      expect(result[:body]).to eq expected_result
    end

    it "should handle one side unchanged" do
      left = "53fa7539-8d7d-4d88-af23-dd0ab2dfe81d"
      base = "Article title"
      right = "Article title"

      result = Dyph3::Differ.merge_text(left, base, right, include_base: false, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
      expect(result[:conflict]).to eq(0)
      expect(result[:body]).to eq left
    end
  end

  describe 'should have conflict' do
    right = """\n<h2>\n This is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n</p>\n"""
    left = """\n<h2>\nThis is cool.\n</h2>\n<p>\nHi I'm a paragraph.\nI'm another sentence in the paragraph.\n</p>\n"""
    base = """\n<h2>\n This is cool.\n</h2>\n<p>\n Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n</p>\n"""
    expected_result = "\n<h2>\nThis is cool.\n</h2>\n<p>\n<<<<<<< start\nHi I'm a paragraph.\nI'm another sentence in the paragraph.\n|||||||\n Hi I'm a paragraph.\nI'm a sentence in the paragraph.\n=======\n Hi I'm a paragraph.\nI'm a second sentence in the paragraph.\n>>>>>>> changed_b\n</p>"

    it "should produce a conflict" do
      result = Dyph3::Differ.merge_text(left, base, right, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
      expect(result[:conflict]).to be_true
      expect(result[:body]).to eq expected_result
    end
  end
end
