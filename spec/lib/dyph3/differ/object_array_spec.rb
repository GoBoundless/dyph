require 'spec_helper'
describe Dyph3::Differ do
  let(:identity) { ->(x){ x } }
  two_way_differs.each do |current_differ|
    describe "test split  " do
      let(:base) { [:a, :b, :c] }
      let(:left) { [:a, :b, :c] }
      let(:right) { [:a, :v, :c] }

      let(:merged_array) do
         Dyph3::Differ.merge_text(left, base, right, split_function: identity, join_function: identity, current_differ: current_differ )
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
        Dyph3::Differ.merge_text(left, base, right, current_differ: current_differ )
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
        Dyph3::Differ.merge_text(left, base, right, current_differ: current_differ )
      end

      it "should have merged successfully" do
        expect(merged_array.joined_results.first[:conflict_custom]).to eq [:tuna]
      end
    end
  end
end