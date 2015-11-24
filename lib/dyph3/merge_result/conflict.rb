module Dyph3
  class MergeResult::Conflict < Dyph3::MergeResult
    def joined_results
      #allows for custom conflict handler
      if @conflict_handler
        @conflict_handler[results]
      else
        typed_results
      end
    end
  end
end
