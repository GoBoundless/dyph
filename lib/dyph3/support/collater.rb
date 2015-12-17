module Dyph3
  module Support
    module Collater
      extend self
      def collate_merge(merge_result, join_function, conflict_handler)
        if merge_result.empty?
          Dyph3::MergeResult.new([Outcome::Resolved.new([])], join_function)
        else
          merge_result = combine_non_conflicts(merge_result)
          if (merge_result.length == 1 && merge_result.first.resolved?)
            Dyph3::MergeResult.new(merge_result, join_function)
          else
            Dyph3::MergeResult.new(merge_result, join_function, conflict: true, conflict_handler: conflict_handler)
          end
        end
      end

      private
        # @param [in] results
        # @return the list of conflicts with contiguous parts merged if they are non_conflicts
        def combine_non_conflicts(results)
          results.reduce([]) do |rs, r|
            if rs.any? && rs.last.resolved? && r.resolved?
              rs.last.combine(r)
            else
              rs << r
            end
            rs
          end
        end
    end
  end
end