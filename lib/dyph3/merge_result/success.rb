module Dyph3
  class MergeResult::Success < Dyph3::MergeResult
    def joined_results
      # in a success the results is only one non-conflict
      # e.g.[{type: :non_conflict, text: ["..."]}]
      @join_function[results[0][:text]]
    end
  end
end