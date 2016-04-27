require 'spec_helper'

describe Dyph::Support::AssignAction do
  describe ".get_action" do
    let(:action_assigner) { Dyph::Support::AssignAction }
    it "should return a change" do
      expected_result = [:change, 2, 3, 2, 3]
      expect( action_assigner.get_action lo_a: 1, lo_b: 1, hi_a: 2,  hi_b: 2).to eq expected_result
    end

    it "should return an add" do
      expected_result = [:add, 3, 2, 2, 5]
      expect( action_assigner.get_action lo_a: 2 , lo_b: 1, hi_a: 1,  hi_b: 4).to eq  expected_result
    end
    
    it "should return a delete" do
      expected_result = [:delete, 1, 2, 2, 1]
      expect( action_assigner.get_action lo_a: 0 , lo_b: 1, hi_a: 1,  hi_b: 0).to eq  expected_result
    end
  end

end