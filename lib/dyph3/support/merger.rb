module Dyph3
  module Support
    class Merger
      attr_reader :result, :current_differ
      def self.merge(left, base, right, current_differ: Dyph3::TwoWayDiffers::HeckelDiff)
        merger = Merger.new(left: left, base: base, right: right, current_differ: current_differ)
        merger.execute_three_way_merge
        merger.result
      end

      def execute_three_way_merge
        d3 = Diff3.execute_diff(@text3.left, @text3.base, @text3.right, @current_differ)
        chunk_descs = d3.map { |raw_chunk_desc| ChunkDesc.new(raw_chunk_desc) }
        i2 = 1
        chunk_descs.each do |chunk_desc|
          initial_text = []

          (i2 ... chunk_desc.base_lo).each do |lineno|                  # exclusive (...)
            initial_text << @text3.base[lineno - 1]
          end

          #initial_text = initial_text.join("\n") + "\n"
          @result << Dyph3::Outcome::Resolved.new(initial_text) unless initial_text.empty?

          interpret_chunk(chunk_desc)
          #assign i2 to be the line in base after the conflict
          i2 = chunk_desc.base_hi + 1
        end

        #finish by putting all text after the last conflict into the @result body.
        ending_text = accumulate_lines(i2, @text3.base.length, @text3.base)
        @result << Dyph3::Outcome::Resolved.new(ending_text) unless ending_text.empty?
      end

      protected

        def initialize(left:, base:, right:, current_differ:)
          @result = []
          @current_differ = current_differ
          @text3 = Text3.new(left: left, right: right, base: base)
        end

        def set_conflict(chunk_desc)
          conflict = Dyph3::Outcome::Conflicted.new(
            left:   accumulate_lines(chunk_desc.left_lo, chunk_desc.left_hi, @text3.left),
            base:   accumulate_lines(chunk_desc.base_lo, chunk_desc.base_hi, @text3.base),
            right:  accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, @text3.right)
          )
          @result << conflict
        end

        def determine_conflict(d, text_a, text_b)
          ia = 1
          d.each do |raw_chunk_desc|
            chunk_desc = ChunkDesc.new(raw_chunk_desc)
            (ia ... chunk_desc.left_lo).each do |lineno|
              @result <<  Dyph3::Outcome::Resolved.new(accumulate_lines(ia, lineno, text_a))
            end

            outcome = if chunk_desc.action == :change
              Outcome::Conflicted.new(
                left: accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, text_b),
                right: accumulate_lines(chunk_desc.left_lo, chunk_desc.left_hi, text_a),
                base: []
              )
            elsif chunk_desc.action == :add
              Outcome::Resolved.new(
                accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, text_b)
              )
            end
            ia = chunk_desc.left_hi + 1
            @result << outcome if outcome
          end

          final_text = accumulate_lines(ia, text_a.length + 1, text_a)
          @result <<  Dyph3::Outcome::Resolved.new(final_text) unless final_text.empty?
        end

        def set_text(orig_text, lo, hi)
          text = [] # conflicting lines in right
          (lo .. hi).each do |i|                   # inclusive(..)
            text << orig_text[i - 1]
          end
          text
        end

        def _conflict_range(chunk_desc)
          text_a = set_text(@text3.right, chunk_desc.right_lo,  chunk_desc.right_hi)
          text_b = set_text(@text3.left , chunk_desc.left_lo,   chunk_desc.left_hi)

          d = @current_differ.diff(text_a, text_b)

          if (_assoc_range(d, :change) || _assoc_range(d, :delete)) && chunk_desc.base_lo <= chunk_desc.base_hi
            set_conflict(chunk_desc)
          else
            determine_conflict(d, text_a, text_b)
          end
        end

        def interpret_chunk(chunk_desc)
          if chunk_desc.action == :choose_left
            # 0 flag means choose left.  put lines chunk_desc[1] .. chunk_desc[2] into the @result body.
            temp_text = accumulate_lines(chunk_desc.left_lo, chunk_desc.left_hi, @text3.left)
            # they deleted it, don't use if its only a new line
            @result <<  Dyph3::Outcome::Resolved.new(temp_text) unless temp_text.empty?
          elsif chunk_desc.action != :possible_conflict
            # A flag means choose right.  put lines chunk_desc[3] to chunk_desc[4] into the @result body.
            temp_text = accumulate_lines(chunk_desc.right_lo, chunk_desc.right_hi, @text3.right)
            @result << Dyph3::Outcome::Resolved.new(temp_text)
          else
            _conflict_range(chunk_desc)
          end
        end

        # @param [in] diff        conflicts in diff structure
        # @param [in] diff_type   type of diff looked for in diff
        # @returns diff_type if any conflicts in diff are of type diff_type.  otherwise returns nil
        def _assoc_range(diff, diff_type)
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
        def accumulate_lines(lo, hi, text)
          lines = []
          (lo .. hi).each do |lineno|
            lines << text[lineno - 1] unless text[lineno - 1].nil?
          end
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
end