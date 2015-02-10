module Dyph3
  class Merger
    def self.merge(left, origtext, right)
      res = []
      d3 = Diff3.execute_diff(left, origtext, right, current_differ)
      text3 = [left, right, origtext]
      left, right, base  = [0,1,2]
      i2 = 1
      base_lo, base_hi  = [5,6]

      d3.each do |chunk_desc|
        #chunk_desc[5] is the line that this new conflict starts
        #put base text from lines i2 ... chunk_desc[5] into the resulting body.
        #initial_text = accumulate_lines(i2, chunk_desc[5] + 1, text3[2])
        initial_text = []

        (i2 ... chunk_desc[base_lo]).each do |lineno|                  # exclusive (...)
          initial_text << text3[base][lineno - 1]
        end

        initial_text = initial_text.join("\n") + "\n"
        res << {type: :non_conflict, text: initial_text} unless initial_text.length == 1

        res = interpret_chunk(res, chunk_desc, text3)
        #binding.pry
        #assign i2 to be the line in origtext after the conflict
        i2 = chunk_desc[base_hi] + 1
        #binding.pry
      end

      #finish by putting all text after the last conflict into the resulting body.
      ending_text = accumulate_lines(i2, text3[base].length, text3[base])
      res << {type: :non_conflict, text: ending_text} unless ending_text.empty?

      res
    end

    private
      def self.current_differ
        Dyph3::TwoWayDiffers::HeckelDiff
        #Dyph3::TwoWayDiffers::ResigDiff
      end

      def self._conflict_range(text3, chunk_desc, res)
        left, right, base  = [0,1,2]
        left_lo, left_hi, right_lo, right_hi, base_lo, base_hi = [1,2,3,4,5,6]

        text_a = [] # conflicting lines in right
        (chunk_desc[right_lo] .. chunk_desc[right_hi]).each do |i|                   # inclusive(..)
          text_a << text3[right][i - 1]
        end
        text_b = [] # conflicting lines in left
        (chunk_desc[left_lo] .. chunk_desc[left_hi]).each do |i|                   # inclusive(..)
          text_b << text3[left][i - 1]
        end

        d = current_differ.diff(text_a, text_b)

        if (_assoc_range(d, :change) || _assoc_range(d, :delete)) && chunk_desc[base_lo] <= chunk_desc[base_hi]
          conflict = {type: :conflict}
          conflict[:ours]   = accumulate_lines(chunk_desc[left_lo], chunk_desc[left_hi], text3[left])
          conflict[:base]   = accumulate_lines(chunk_desc[base_lo], chunk_desc[base_hi], text3[base])
          conflict[:theirs] = accumulate_lines(chunk_desc[right_lo], chunk_desc[right_hi], text3[right])
          res << conflict
          return res
        end

        ia = 1
        d.each do |r2|
          (ia ... r2[1]).each do |lineno|
            non_conflict = {type: :non_conflict}
            non_conflict[:text] = accumulate_lines(ia, lineno, text_a)
            res << non_conflict
          end

          conflict = {}

          if r2[0] == :change
            conflict[:type] =  :conflict
            conflict[:ours] = accumulate_lines(r2[3], r2[4], text_b)
            conflict[:theirs] = accumulate_lines(r2[1], r2[2], text_a)
          elsif r2[0] == :add
            conflict[:type] = :non_conflict
            conflict[:text] = accumulate_lines(r2[3], r2[4], text_b)
          end

          conflict[:base] = "" if conflict[:type] == :conflict && conflict[:base].nil?
          ia = r2[2] + 1
          res << conflict unless conflict.empty?
        end

        final_text = accumulate_lines(ia, text_a.length + 1, text_a)

        res << {type: :non_conflict, text: final_text} unless final_text == "\n"
        res
      end

      def self.interpret_chunk(res, chunk_desc, text3)
        if chunk_desc[0] == :choose_left
          # 0 flag means choose left.  put lines chunk_desc[1] .. chunk_desc[2] into the resulting body.
          temp_text = accumulate_lines(chunk_desc[1], chunk_desc[2], text3[0])
          # they deleted it, don't use if its only a new line
          res << {type: :non_conflict, text: temp_text} unless temp_text == "\n"
        elsif chunk_desc[0] != :possible_conflict
          # A flag means choose right.  put lines chunk_desc[3] to chunk_desc[4] into the resulting body.
          temp_text = accumulate_lines(chunk_desc[3], chunk_desc[4], text3[1])
          res << {type: :non_conflict, text: temp_text}
        else
          res = _conflict_range(text3, chunk_desc, res)
        end
        res
      end

      # @param [in] diff        conflicts in diff structure
      # @param [in] diff_type   type of diff looked for in diff
      # @returns diff_type if any conflicts in diff are of type diff_type.  otherwise returns nil
      def self._assoc_range(diff, diff_type)
        diff.each do |d|
          if d[0] == diff_type
            return d
          end
        end
        nil
      end

      # @param [in] lo        indec for beginning of accumulation range
      # @param [in] hi        index for end of accumulation range
      # @param [in] text      array of lines of text
      # @returns a string of lines lo to high joined by new lines, with a trailing new line. 
      def self.accumulate_lines(lo, hi, text)
        lines = []
        (lo .. hi).each do |lineno|
          lines << text[lineno - 1]
        end
        lines = lines.join("\n")
        lines += "\n" unless hi == text.length
        lines
      end
    end
end