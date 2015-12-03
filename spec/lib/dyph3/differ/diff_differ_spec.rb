require 'spec_helper'

describe Dyph3::Differ do
  let(:differs) {  two_way_differs }
  let(:set_up) do
    -> (l,b,r) {
      differs.map do |current_differ|
        Dyph3::Differ.merge(l, b, r, current_differ: current_differ).joined_results
      end
    }
  end
  let(:test_combos) do
    -> (l,b,r) {
      # [l,l,l], [l,l,b] ... [r,r,r]
      [l,b,r].repeated_combination(3).each do |c1, c2, c3|
        results = set_up[c1, c2, c3]
        expect(results.all?{ |merge_result| merge_result == results[0] }).to be true
      end
    }
  end

  describe "block changes" do
    let(:p1) { Faker::Lorem.paragraphs(20)}
    let(:p2) { Faker::Lorem.paragraphs(20)}
    let(:p3) { Faker::Lorem.paragraphs(20)}

    it "should pass repeated_combinations" do
      test_combos[p1,p2,p3]
    end
  end

  context "shuffled changes" do
    let(:p1) { Faker::Lorem.paragraphs(20)}
    let(:s1) { p1.shuffle }
    let(:s2) { p1.shuffle }
    let(:s3) { p1.shuffle }

    it "should pass repeated_combinations" do
      test_combos[s1,s2,s3]
    end
  end



end