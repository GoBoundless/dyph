module Dyph3
  module Support
    module Collater
      extend self
      def collate_merge(left, base, right, merge_result)
        if merge_result.empty?
          # this happens when all texts are empty
          conflict = false
          final_result = [{type: :non_conflict, text: []}]
          [[], conflict, final_result]
        else
          merge_result = merge_non_conflicts(merge_result)
          get_text_conflict_result(base, merge_result)
        end
      end

      private

        def get_text_conflict_result(base, merge_result)
          if (merge_result.length == 1 && merge_result[0][:type] == :non_conflict)
            conflict = false
            text = merge_result[0][:text]
            final_result = [{type: :non_conflict, text: merge_result[0][:text]}]
          else
            text = base
            conflict = true
            final_result = merge_result
          end
          [text, conflict, final_result]
        end

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