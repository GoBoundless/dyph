require 'spec_helper'

describe Dyph3::Support::SanityCheck do
  let(:sanity_checker) { Dyph3::Support::SanityCheck }
  let(:error)          { Dyph3::Support::BadMergeException }
  describe ".ensure_no_lost_data" do
    it "should be calm if nothing happened" do
      collated_text = [{type: :non_conflict, :text=>[""]}]
      expect(sanity_checker.ensure_no_lost_data([""], [""], [""], collated_text)).to eq nil
    end

    it "should be calm if all the text is present" do
      collated_text = [
        {type: :non_conflict, :text=>["the dogs"]},
        {type: :non_conflict, :text=>["are"]},
        {type: :non_conflict, :text=>["out"]}
      ]
      expect(sanity_checker.ensure_no_lost_data(["the dogs"], ["are"], ["out"], collated_text)).to eq nil
    end

    it "should raise and execption if the text is missing somewhere" do
      collated_text =
      [
        {type: :non_conflict, :text=>["the dogs are in"]},
        {type: :non_conflict, :text=>["are"]},
        {type: :non_conflict, :text=>["in"]}
      ]

      expect { sanity_checker.ensure_no_lost_data(["the"], ["dogs"], ["are out"], collated_text)}.to raise_error error
    end
  end
end