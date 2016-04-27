require 'spec_helper'

describe Dyph::Outcome::Resolved do
  describe "simple conflict" do
    let(:outcome) { Dyph::Outcome::Resolved.new([:result]) }
    let(:other_outcome) { Dyph::Outcome::Resolved.new([:other_result]) }

    describe "#resolved?" do
      subject { outcome.resolved? }
      it { is_expected.to be true}
    end

   describe "#conflicted?" do
      subject { outcome.conflicted? }
      it { is_expected.to be false}
    end

    describe "#==" do
      describe "identity" do
        subject { outcome == outcome }
        it { is_expected.to be true}
      end

      describe "similar" do
        let(:other_outcome) { Dyph::Outcome::Resolved.new([:result]) }
        subject { outcome == other_outcome }
        it { is_expected.to be true}
      end

      describe "different" do
        subject { outcome == other_outcome }
        it { is_expected.to be false}
      end
    end

    describe "#hash" do
      describe "identity" do
        subject { outcome.hash == outcome.hash }
        it { is_expected.to be true}
      end

      describe "similar" do
        let(:other_outcome) { Dyph::Outcome::Resolved.new([:result]) }
        subject { outcome.hash == other_outcome.hash }
        it { is_expected.to be true}
      end

      describe "different" do
        subject { outcome.hash == other_outcome.hash }
        it { is_expected.to be false}
      end
    end

    describe "#apply" do
      let(:outcome) { Dyph::Outcome::Resolved.new([:result]) }
      subject { outcome.apply( ->(x){ x.first } )}
      let(:result) { Dyph::Outcome::Resolved.new(:result) }
      it { is_expected.to eq result}
    end

    describe "#combine" do
      subject { outcome.combine(other_outcome).result }
      it { is_expected.to eq [:result, :other_result]}

      describe "#set_combiner" do
        before { outcome.set_combiner( ->(x , y) { y } )}
        subject { outcome.combine(other_outcome).result }
        it { is_expected.to eq [:other_result]}
      end
    end


  end
end