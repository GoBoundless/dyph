module Dyph3
  class MergeResult::Conflict < Dyph3::MergeResult
    def results
      @post_processor[value]
    end
  end
end
