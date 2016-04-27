require 'spec_helper'

describe Dyph::Outcome::Conflicted do
  describe "simple conflict" do
    let(:conflict) { Dyph::Outcome::Conflicted.new(left: [:l], base: [:b], right: [:r] ) }
    let(:other_conflict) { Dyph::Outcome::Conflicted.new(left: [:x], base: [:b], right: [:r] ) }
    describe "#conflicted?" do
      subject { conflict.conflicted? }
      it { is_expected.to be true}
    end

    describe "#resolved?" do
      subject { conflict.resolved? }
      it { is_expected.to be false}
    end

    describe "#==" do
      describe "identity" do
        subject { conflict == conflict }
        it { is_expected.to be true}
      end

      describe "similar" do
        let(:other_conflict) { Dyph::Outcome::Conflicted.new(left: [:l], base: [:b], right: [:r] ) }
        subject { conflict == other_conflict }
        it { is_expected.to be true}
      end

      describe "different" do
        subject { conflict == other_conflict }
        it { is_expected.to be false}
      end
    end

    describe "#hash" do
      describe "identity" do
        subject { conflict.hash == conflict.hash }
        it { is_expected.to be true}
      end

      describe "similar" do
        let(:other_conflict) { Dyph::Outcome::Conflicted.new(left: [:l], base: [:b], right: [:r] ) }
        subject { conflict.hash == other_conflict.hash }
        it { is_expected.to be true}
      end

      describe "different" do
        let(:other_conflict) { Dyph::Outcome::Conflicted.new(left: [:x], base: [:b], right: [:r] ) }
        subject { conflict.hash == other_conflict.hash }
        it { is_expected.to be false}
      end
    end

    describe "#apply" do
      subject { conflict.apply( ->(x){ x.first } )}
      let(:result) { Dyph::Outcome::Conflicted.new(left: :l, base: :b, right: :r ) }
      it { is_expected.to eq result}
    end
  end
end