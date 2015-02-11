module Dyph3
  class Collater
    def self.collate_merge(left, base, right, merge_result)
      if merge_result.empty?
        # this happens when all texts are ""
        text = ""
        conflict = false
        final_result = [{type: :non_conflict, text: ""}]
        [text, conflict, final_result]
      else
        merge_result = handle_trailing_newline(left, base, right, merge_result)
        merge_result = merge_non_conflicts(merge_result)
        get_text_conflict_result(base, merge_result)
      end
    end

    private

      def self.get_text_conflict_result(base, merge_result)
        if (merge_result.length == 1 && merge_result[0][:type] == :non_conflict) || (merge_result.kind_of?(Hash) && merge_result[:type] == :non_conflict)
          conflict = false
          if merge_result[0].nil?
            text = merge_result[:text]
            final_result = [{type: :non_conflict, text: merge_result[:text]}]
          else
            text = merge_result[0][:text]
            final_result = [{type: :non_conflict, text: merge_result[0][:text]}]
          end
        else
          text = base
          conflict = true
          final_result = merge_result
        end
        [text, conflict, final_result]
      end

      # @param [in] conflicts
      # @returns the list of conflicts with contiguous parts merged if they are non_conflicts
      def self.merge_non_conflicts(res, i = 0)
        return res if i == res.length - 1

        if res[i][:type] == :non_conflict && res[i+1][:type] == :non_conflict
          res[i][:text] += "\n" unless res[i][:text][-1] == "\n"
          res[i][:text] += res[i+1][:text]
          res.delete_at(i+1)
          merge_non_conflicts(res, i)
        else
          merge_non_conflicts(res, i+1)
        end
      end
      # @param [in] ours        unsplit text of ours
      # @param [in] base        unsplit text of base
      # @param [in] theirs      unsplit text of theirs
      # @returns the result with the possible trailing newlines added if necessary.
      def self.handle_trailing_newline(ours, base, theirs, result)
        last = result[-1]
        if last[:type] == :non_conflict && last[:text] != "\n"
          last[:text] += "\n" if add_trailing_newline?(ours, base, theirs)
        elsif last[:type] == :non_conflict && last[:text] == "\n"
          result = result[0...-1]
        elsif result[-1][:type] == :conflict
          last[:ours] += "\n" if ours[-1] == "\n"
          last[:theirs] += "\n" if theirs[-1] == "\n"
          last[:base] += "\n" if base[-1] == "\n"
        end
        result
      end

      # @param [in] ours        unsplit text of ours
      # @param [in] base        unsplit text of base
      # @param [in] theirs      unsplit text of theirs
      # @returns if a trailing newline should be added.  It should be added if all texts had a trailing newline,
      #    or if one or both changes added a new line when there was not one before.
      def self.add_trailing_newline?(ours, base, theirs)
        our_newline = ours[-1] == "\n"
        base_newline = base[-1] == "\n"
        their_newline = theirs[-1] == "\n"
        return (our_newline && base_newline && their_newline) || !base_newline && (our_newline || their_newline)
      end
  end
end