module Dyph3
  class MergeResult::Conflict < Dyph3::MergeResult
    def joined_results
      if @conflict_handler
        @conflict_handler[value]
      else
        typed_results
      end
    end
  end
end
