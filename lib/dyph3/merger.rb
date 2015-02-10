module Dyph3
  class Merger
    def self.merge(left, origtext, right)
      res = []
      d3 = Diff3.execute_diff(left, origtext, right, current_differ)
      text3 = Text3.new(left: left, right: right, base: origtext)
      i2 = 1
      d3.each do |raw_chunk_desc|
        chunk_desc = ChunkDesc.new(raw_chunk_desc)
        #chunk_desc[5] is the line that this new conflict starts
        #put base text from lines i2 ... chunk_desc[5] into the resulting body.
        #initial_text = accumulate_lines(i2, chunk_desc[5] + 1, text3[2])
        initial_text = []

        (i2 ... chunk_desc.base_lo).each do |lineno|                  # exclusive (...)
          initial_text << text3.base[lineno - 1]
        end

        initial_text = initial_text.join("\n") + "\n"
        res << {type: :non_conflict, text: initial_text} unless initial_text.length == 1

        res = interpret_chunk(res, chunk_desc, text3)
        #assign i2 to be the line in origtext after the conflict
        i2 = chunk_desc.base_hi + 1
      end

      #finish by putting all text after the last conflict into the resulting body.
      ending_text = accumulate_lines(i2, text3.base.length, text3.base)
      res << {type: :non_conflict, text: ending_text} unless ending_text.empty?
      res
    end

    private
      def self.current_differ
        Dyph3::TwoWayDiffers::HeckelDiff
        #Dyph3::TwoWayDiffers::ResigDiff
      end


      def self.set_conflict(chunk_desc, text3, res)
        conflict = {type: :conflict}
        conflict[:ours]   = accumulate_lines(chunk_desc.left_lo, chunk_desc.left_hi, text3.left)
        conflict[:base]   = accumulate_lines(chunk_desc.base_lo, chunk_desc.base_hi, text3.base)
        conflict[:theirs] = accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, text3.right)
        res << conflict
        res
      end

      def self.determine_conflict(d, text_a, text_b, res)
        ia = 1
        d.each do |raw_chunk_desc|
          chunk_desc = ChunkDesc.new(raw_chunk_desc)
          (ia ... chunk_desc.left_lo).each do |lineno|
            non_conflict = {type: :non_conflict}
            non_conflict[:text] = accumulate_lines(ia, lineno, text_a)
            res << non_conflict
          end

          conflict = {}

          if chunk_desc.action == :change
            conflict[:type] =  :conflict
            conflict[:ours] = accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, text_b)
            conflict[:theirs] = accumulate_lines(chunk_desc.left_lo, chunk_desc.left_hi, text_a)
          elsif chunk_desc.action == :add
            conflict[:type] = :non_conflict
            conflict[:text] = accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, text_b)
          end

          conflict[:base] = "" if conflict[:type] == :conflict && conflict[:base].nil?
          ia = chunk_desc.left_hi + 1
          res << conflict unless conflict.empty?
        end

        final_text = accumulate_lines(ia, text_a.length + 1, text_a)

        res << {type: :non_conflict, text: final_text} unless final_text == "\n"
        res
      end

      def self.set_text(orig_text, lo, hi)
        text = [] # conflicting lines in right
        (lo .. hi).each do |i|                   # inclusive(..)
          text << orig_text[i - 1]
        end
        text
      end

      def self._conflict_range(text3, chunk_desc, res)
        text_a = set_text(text3.right, chunk_desc.right_lo,  chunk_desc.right_hi)
        text_b = set_text(text3.left , chunk_desc.left_lo,   chunk_desc.left_hi)

        d = current_differ.diff(text_a, text_b)

        if (_assoc_range(d, :change) || _assoc_range(d, :delete)) && chunk_desc.base_lo <= chunk_desc.base_hi
          set_conflict(chunk_desc, text3, res)
        else
          determine_conflict(d, text_a, text_b, res)
        end
      end

      def self.interpret_chunk(res, chunk_desc, text3)
        if chunk_desc.action == :choose_left
          # 0 flag means choose left.  put lines chunk_desc[1] .. chunk_desc[2] into the resulting body.
          temp_text = accumulate_lines(chunk_desc.left_lo, chunk_desc.left_hi, text3.left)
          # they deleted it, don't use if its only a new line
          res << {type: :non_conflict, text: temp_text} unless temp_text == "\n"
        elsif chunk_desc.action != :possible_conflict
          # A flag means choose right.  put lines chunk_desc[3] to chunk_desc[4] into the resulting body.
          temp_text = accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, text3.right)
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

  class Text3
    attr_reader :left, :right, :base
    def initialize(left:, right:, base:)
      @left = left
      @right = right
      @base = base
    end
  end

  class ChunkDesc
    attr_reader :action, :left_lo, :left_hi, :right_lo, :right_hi, :base_lo, :base_hi
    def initialize(raw_chunk)
      @action   = raw_chunk[0]
      @left_lo  = raw_chunk[1]
      @left_hi  = raw_chunk[2]
      @right_lo = raw_chunk[3]
      @right_hi = raw_chunk[4]
      @base_lo  = raw_chunk[5]
      @base_hi  = raw_chunk[6]
    end
  end
end

