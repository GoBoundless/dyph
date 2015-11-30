module Dyph3
  module Support
    module Collater
      extend self
      def collate_merge(merge_result, join_function, conflict_handler)
        if merge_result.empty?
          Dyph3::MergeResult.new([Outcome::Resolved.new([])], join_function)
        else
          merge_result = collapse_non_conflicts(merge_result)
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
        def collapse_non_conflicts(res, i = 0)
          res.reduce([]) do |results, r|
            if results.any? && results.last.resolved? && r.resolved?
              results.last.combine(r)
            else
              results << r
            end
            results
          end
        end
    end
  end
end