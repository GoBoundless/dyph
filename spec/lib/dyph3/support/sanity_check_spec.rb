require 'spec_helper'

describe Dyph3::Support::SanityCheck do
  let(:sanity_checker) { Dyph3::Support::SanityCheck }
  let(:error)          { Dyph3::Support::BadMergeException }
  describe ".ensure_no_lost_data" do
    it "should be calm if nothing happened" do
      collated_text = [Dyph3::Outcome::Resolved.new([""])]
      expect(sanity_checker.ensure_no_lost_data([""], [""], [""], collated_text)).to eq nil
    end

    it "should be calm if all the text is present" do
      collated_text = [
        Dyph3::Outcome::Resolved.new(["the dogs"]),
        Dyph3::Outcome::Resolved.new(["are"]),
        Dyph3::Outcome::Resolved.new(["out"])
      ]
      expect(sanity_checker.ensure_no_lost_data(["the dogs"], ["are"], ["out"], collated_text)).to eq nil
    end

    it "should raise and execption if the text is missing somewhere" do
      collated_text =
      [
        Dyph3::Outcome::Resolved.new(["the dogs are in"]),
        Dyph3::Outcome::Resolved.new(["are"]),
        Dyph3::Outcome::Resolved.new(["in"])
      ]

      expect { sanity_checker.ensure_no_lost_data(["the"], ["dogs"], ["are out"], collated_text)}.to raise_error error
    end
  end
end