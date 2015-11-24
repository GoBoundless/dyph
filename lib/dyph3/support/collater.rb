module Dyph3
  module Support
    module Collater
      extend self
      def collate_merge(merge_result, join_function, conflict_function)
        if merge_result.empty?
          Dyph3::MergeResult::Success.new([{type: :non_conflict, text: []}], join_function)
        else
          merge_result = merge_non_conflicts(merge_result)
          if (merge_result.length == 1 && merge_result[0][:type] == :non_conflict)
            Dyph3::MergeResult::Success.new([{type: :non_conflict, text: merge_result[0][:text]}], join_function)
          else
            Dyph3::MergeResult::Conflict.new(merge_result, join_function, conflict_function)
          end
        end
      end

      private
        # @param [in] conflicts
        # @returns the list of conflicts with contiguous parts merged if they are non_conflicts
        def merge_non_conflicts(res, i = 0)
          while i < res.length - 1
            if res[i][:type] == :non_conflict && res[i+1][:type] == :non_conflict
              #res[i][:text] += "\n" unless res[i][:text][-1] == "\n"
              res[i][:text] += res[i+1][:text]
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