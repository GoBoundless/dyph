require 'spec_helper'

describe Dyph3::TwoWayDiffers::HeckelDiff do
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

    describe ".merge_two_way_diff" do
      it "show all no changes" do
        t1 = "a b c d".split
        diff = Dyph3::Differ.merge_two_way_diff(t1, t1)
        expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange]
      end


      it "should show an add" do
        t1 = "a b c d".split
        t2 = "a b c d e".split
        diff = Dyph3::Differ.merge_two_way_diff(t1, t2)
        expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Add]
      end

      it "should show a delete" do
        t1 = "a b c d".split
        t2 = "a b c".split
        diff = Dyph3::Differ.merge_two_way_diff(t1, t2)
        expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete]
      end

      it "should show a change" do
        t1 = "a b c d".split
        t2 = "a b z d".split
        diff = Dyph3::Differ.merge_two_way_diff(t1, t2)
        expect(diff.map(&:class)).to eq [Dyph3::NoChange, Dyph3::NoChange, Dyph3::Delete, Dyph3::Add, Dyph3::NoChange]
      end
    end
  end
end