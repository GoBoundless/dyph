require 'spec_helper'

describe Dyph3::Differ do

  let(:run_all_diffs) do
    -> (l,b,r) {
      two_way_differs.product(three_way_differs).map do |diff2, diff3|
        Dyph3::Differ.merge(l, b, r, diff2: diff2, diff3: diff3).joined_results
      end
    }
  end
  let(:test_combos) do
    -> (l,b,r) {
      # [l,l,l], [l,l,b] ... [r,r,r]
      [l,b,r].repeated_combination(3).each do |c1, c2, c3|
        results = run_all_diffs[c1, c2, c3]
        binding.pry unless results.all?{ |merge_result| merge_result == results[0] }
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
    (1..100).each do |i|
      let(:ps) { Faker::Lorem.paragraphs(20)}
      let(:s1) { ps.shuffle }
      let(:s2) { ps.shuffle }
      let(:s3) { ps.shuffle }

      it "should pass repeated_combinations" do
        test_combos[s1,s2,s3]
      end
    end
  end
end