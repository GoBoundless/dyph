module Dyph3
  class MergeResult
    attr_reader :value
    def initialize(value, post_processor)
      @value = value
      @post_processor = post_processor
    end

    def success?
      self.class == Dyph3::MergeResult::Success
    end

    def conflict?
      self.class == Dyph3::MergeResult::Conflict
    end
  end


end