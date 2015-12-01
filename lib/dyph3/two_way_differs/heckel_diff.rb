module Dyph3
  module TwoWayDiffers
    class HeckelDiff
      # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

      def self.execute_diff(old_text_array, new_text_array)
        raise ArgumentError, "Argument is not an array." unless old_text_array.is_a?(Array) && new_text_array.is_a?(Array)

        diff_result = diff(old_text_array, new_text_array)

        # convert to the Resig differ's output to be consistent
        convert_to_resig_output(diff_result, old_text_array, new_text_array)
      end

      # Two-way diff based on the algorithm by P. Heckel.
      # @param [in] text_a Array of lines of first text.
      # @param [in] text_b Array of lines of second text.
      # @returns TODO
      def self.diff(text_a, text_b)
        d    = []
        uniq = set_freq(text_a, text_b)
        uniq.sort!{|a, b| a[0] <=> b[0]}    # sort by the line in which the line was found in a
        a1, b1 = [0, 0]
        # set a1 and b1 to be the first line where there is a change.
        a1, b1 = find_next_difference(text_a, text_b, a1, b1)
        # start with a1, b1 being the lines before the first change.
        # for each pair of lines in uniq which definitely match eachother:
        uniq.each do |a_uniq, b_uniq|
          # (a_uniq < a1 || b_uniq < b1) == true guarentees there is not a change (since we walked a1 and b1 to changes before this section, and at the end of each block)
          # a1 and b1 are always the lines right before the next change.
          if a_uniq < a1 || b_uniq < b1
            next
          end
          # a0, b0 are the last agreeing lines before a change.
          a0, a1, b0, b1 = find_changes_range(text_a, text_b, a_uniq, b_uniq, a1, b1)
          d = add_change(d, a0, a1, b0, b1)

          #set a1 and b1 to be the words after the matching uniq word
          a1, b1 = [a_uniq + 1, b_uniq + 1]
          a1, b1 = find_next_difference(text_a, text_b, a1, b1)
        end

        d
      end

      private
        def self.find_changes_range(text_a, text_b, a_uniq, b_uniq, a1, b1)
          a0, b0 = [a1, b1]
          # we know a_uniq to be the next line which has a corresponding b_uniq. so a1 = last line of potential change (as does b1)
          a1, b1 = [a_uniq - 1, b_uniq - 1]
          # loop from a1 and b1's new positions down towards a0, b0.  stop when there is a change.  This gives the bounds of the change as [a0,a1] and [b0, b1]
          while a0 <= a1 && b0 <= b1
            if text_a[a1] != text_b[b1]   # a change is found on lines a1 and b1.  break out of loop.
              break
            end
            a1 -= 1
            b1 -= 1
          end
          [a0, a1, b0, b1]
        end

        def self.find_next_difference(text_a, text_b, a1, b1)
          while a1 < text_a.length && b1 < text_b.length
            if text_a[a1] != text_b[b1]
              break
            end
            a1 += 1
            b1 += 1
          end
          [a1, b1]
        end

        def self.set_freq(text_a, text_b)
          uniq = [[text_a.length, text_b.length]]
          #start building up uniq, the set of lines which appear exactly once in each text
          freq, ap, bp = [{}, {}, {}]
          text_a.each_with_index do |line, i|
            freq[line] ||= 0
            freq[line] += 2                   # add 2 to the freq of line if its in text_a
            ap[line] = i                    # set ap[line] to the line number
          end
          text_b.each_with_index do |line, i|
            freq[line] ||= 0
            freq[line] += 3                   # add 3 to the freq of line if its in text_b
            bp[line] = i                    # set bp[line] to the line number
          end

          freq.each do |line, x|
            if x == 5
              uniq << [ap[line], bp[line]]    # if the line was uniqely in both, push [line index in a, line index in b])
            end
          end
          uniq
        end

        def self.convert_to_resig_output(heckel_diff, old_text_array, new_text_array)
          chunks = heckel_diff.map { |block| TwoWayChunk.new(block) }

          old_index = 0
          old_text = []
          new_index = 0
          new_text = []
          chunks.each do |chunk|
            old_iteration = 0
            while old_index + old_iteration < chunk.left_lo - 1     # chunk indexes are from 1
              old_text << TextNode.new(text: old_text_array[old_index + old_iteration], row: new_index + old_iteration)
              old_iteration += 1
            end

            new_iteration = 0
            while new_index + new_iteration < chunk.right_lo - 1     # chunk indexes are from 1
              new_text << TextNode.new(text: new_text_array[new_index + new_iteration], row: old_index + new_iteration)
              new_iteration += 1
            end

            old_index += old_iteration
            new_index += new_iteration

            while old_index <= chunk.left_hi - 1     # chunk indexes are from 1
              old_text << old_text_array[old_index]
              old_index += 1
            end

            while new_index <= chunk.right_hi - 1     # chunk indexes are from 1
              new_text << new_text_array[new_index]
              new_index += 1
            end
          end

          iteration = 0
          while old_index + iteration < old_text_array.length
            old_text << TextNode.new(text: old_text_array[old_index + iteration], row: new_index + iteration)
            iteration += 1
          end

          iteration = 0
          while new_index + iteration < new_text_array.length
            new_text << TextNode.new(text: new_text_array[new_index + iteration], row: old_index + iteration)
            iteration += 1
          end

          { old_text: old_text, new_text: new_text}
        end

        # given the calculated bounds of the 2 way diff, create the proper change type and add it to the queue.
        def self.add_change(d, a0, a1, b0, b1)
          if a0 <= a1 && b0 <= b1 # for this change, the bounds are both 'normal'.  the beginning of the change is before the end.
            d << [:change, a0 + 1, a1 + 1, b0 + 1, b1 + 1]
          elsif a0 <= a1
            d << [:delete, a0 + 1, a1 + 1, b0 + 1, b0]
          elsif b0 <= b1
            d << [:add, a0 + 1, a0, b0 + 1, b1 + 1]
          end
          d
        end
    end

    class TwoWayChunk
      attr_reader :action, :left_lo, :left_hi, :right_lo, :right_hi
      def initialize(raw_chunk)
        @action   = raw_chunk[0]
        @left_lo  = raw_chunk[1]
        @left_hi  = raw_chunk[2]
        @right_lo = raw_chunk[3]
        @right_hi = raw_chunk[4]
      end
    end

  end
end