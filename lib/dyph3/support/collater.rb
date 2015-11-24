module Dyph3
  module Support
    module Collater
      extend self
      def collate_merge(merge_result, join_function, conflict_handler)
        if merge_result.empty?
          Dyph3::MergeResult.new([Outcome::Resolved.new([])], join_function)
        else
          merge_result = merge_non_conflicts(merge_result)
          if (merge_result.length == 1 && merge_result.first.resolved?)
            Dyph3::MergeResult.new(merge_result, join_function)
          else
            Dyph3::MergeResult.new(merge_result, join_function, conflict: true, conflict_handler: conflict_handler)
          end
        end
      end

      private
        # @param [in] conflicts
        # @returns the list of conflicts with contiguous parts merged if they are non_conflicts
        def merge_non_conflicts(res, i = 0)
          while i < res.length - 1
            if res[i].resolved? && res[i+1].resolved?
              res[i].combine(res[i+1])
              res.delete_at(i+1)
            else
              i += 1
            end
          end
          res
        end
    end
  end
end