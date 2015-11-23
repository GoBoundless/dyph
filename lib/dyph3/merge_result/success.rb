module Dyph3
  class MergeResult::Success < Dyph3::MergeResult
    def results
      @post_processor[value[0][:text]]
    end
  end
end