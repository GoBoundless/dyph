module Dyph3
  class MergeResult::Success < Dyph3::MergeResult
    def joined_results
      @join_function[value[0][:text]]
    end
  end
end