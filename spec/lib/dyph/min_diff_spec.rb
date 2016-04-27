require 'spec_helper'

describe Dyph do
  describe ".min_diff" do
    let(:left)  { %w[a b c d e f g] }
    let(:right) { %w[d e f g a b c] }
    let(:regular_diff) { Dyph::Differ.two_way_diff(left, right) }
    let(:subject) { Dyph.min_diff(left, right) }

    its(:length) { is_expected.to be < regular_diff.length }

  end
end