require 'spec_helper'

describe Dyph3::TwoWayDiffers::HeckelDiff do
  let(:differ) { Dyph3::TwoWayDiffers::HeckelDiff }
  describe '.diff' do
    let(:iterations) { 10 }
    describe 'no change on an increasing array size, 0 to n - 1' do
      it 'should find no change if right and left match' do
        (0 .. iterations)
          .map  { |i| Array.new(i, 'a') }
          .each { |array| expect( differ.diff(array, array) ).to eq [] }
      end
    end

    describe 'has changes' do
      it "covers one change in the left, incrementing the change index" do
        array = Array.new(iterations, 'a')
        make_diff_array = lambda { |i| array.slice(0,i) + ['z'] + array.slice(i+1, array.length-1) }
        (0 ... iterations)
          .map  { |i| make_diff_array.call(i) }
          .each do |changed_array|
            after_z_pos = changed_array.index('z') + 1
            expect(differ.diff(changed_array, array)).to eq [['c', after_z_pos, after_z_pos, after_z_pos, after_z_pos]]
          end
      end
      
      it "covers one change in the right, incrementing the change index" do
        array = Array.new(iterations, 'a')
        make_diff_array = lambda { |i| array.slice(0,i) + ['z'] + array.slice(i+1, array.length-1) }
        (0 ... iterations)
          .map  { |i| make_diff_array.call(i) }
          .each do |changed_array|
            after_z_pos = changed_array.index('z') + 1
            expect(differ.diff(array, changed_array)).to eq [['c', after_z_pos, after_z_pos, after_z_pos, after_z_pos]]
          end
      end
    end

    describe "complex changes" do
      it "should find a change" do 
        expect(differ.diff("No TV and no beer make and Homer go crazy".split, "No work and much beer make Homer crazy and naked".split)).to eq [['a', 1, 0, 1, 1],['a', 2, 1, 3, 3]]
      end
      it "should find a add in left"      do expect(differ.diff([], ['z'])).to eq [['a', 1, 0, 1, 1]] end
      it "should find a delete in right"  do expect(differ.diff(['z'], [])).to eq [['d', 1, 1, 1, 0]] end
      it "should find a delete in right"  do expect(differ.diff(['a', 'z'], ['a', 'a'])).to eq [['d', 1, 1, 1, 0]] end
    end
  end
end