require 'spec_helper'

describe Dyph3::TwoWayDiffers::HeckelDiff do
  [Dyph3::TwoWayDiffers::HeckelDiff, Dyph3::TwoWayDiffers::OriginalHeckelDiff].each do |differ|
    let(:differ) { Dyph3::TwoWayDiffers::HeckelDiff }
    describe '.diff' do
      let(:iterations) { 10 }

      describe 'no change on an increasing array size, 0 to n - 1' do
        it 'should find no change if right and left match' do
          (0 .. iterations)
            .map  { |i| Array.new(i, Fish.new(:sun_fish)) }
            .each { |array| expect( differ.diff(array, array) ).to eq [] }
        end
      end

      describe 'has changes' do
        it "covers one change in the left, incrementing the change index" do
          array = Array.new(iterations, 'a')
          make_diff_array = lambda { |i| array.slice(0,i) + [:z] + array.slice(i+1, array.length-1) }
          (0 ... iterations)
            .map  { |i| make_diff_array.call(i) }
            .each do |changed_array|
              after_z_pos = changed_array.index(:z) + 1
              expect(differ.diff(changed_array, array)).to eq [[:change, after_z_pos, after_z_pos, after_z_pos, after_z_pos]]
            end
        end

        it "covers one change in the right, incrementing the change index" do
          array = Array.new(iterations, 'a')
          make_diff_array = lambda { |i| array.slice(0,i) + ['z'] + array.slice(i+1, array.length-1) }
          (0 ... iterations)
            .map  { |i| make_diff_array.call(i) }
            .each do |changed_array|
              after_z_pos = changed_array.index('z') + 1
              expect(differ.diff(array, changed_array)).to eq [[:change, after_z_pos, after_z_pos, after_z_pos, after_z_pos]]
            end
        end
      end
    end
  end
end