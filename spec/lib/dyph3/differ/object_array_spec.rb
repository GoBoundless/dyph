require 'spec_helper'
describe Dyph3::Differ do
  two_way_differs.product(three_way_differs).each do |diff2, diff3|
    describe "test split  " do
      let(:base) { [:a, :b, :c] }
      let(:left) { [:a, :b, :c] }
      let(:right) { [:a, :v, :c] }

      let(:merged_array) do
         Dyph3::Differ.merge(left, base, right, diff2: diff2, diff3: diff3 )
      end

      it "should have merged successuffly" do
        expect(merged_array.joined_results).to eq right
      end
    end

    describe "test split objects" do
      let(:base) { Fish.new(:salmon) }
      let(:left) { Fish.new(:salmon) }
      let(:right) { Fish.new(:pollock) }

      let(:merged_array) do
        Dyph3::Differ.merge(left, base, right, diff2: diff2, diff3: diff3 )
      end

      it "should have merged successfully" do
        expect(merged_array.joined_results).to eq right
      end
    end

    describe "test conflict function" do
      let(:base) { Fish.new(:salmon) }
      let(:left) { Fish.new(:trout) }
      let(:right) { Fish.new(:pollock) }

      let!(:merged_array) do
        Dyph3::Differ.merge(left, base, right, diff2: diff2, diff3: diff3 )
      end

      it "should have merged successfully" do
        expect(merged_array.joined_results.first[:conflict_custom]).to eq [:tuna]
      end
    end
  end
end