module Dyph3
  module TwoWayDiffers
    class HeckelDiff
      # Two-way diff based on the algorithm by P. Heckel.
      # @param [in] text_a Array of lines of first text.
      # @param [in] text_b Array of lines of second text.
      # @returns Array of arrays [cmd, our_lo, our_hi, their_lo, their_hi]

      def self.diff(text_a, text_b)
        uniq = find_uniq_matches(text_a, text_b)
        # start with a1, b1 being the lines before the first change.
        # for each pair of lines in uniq which definitely match eachother:
        a1, b1 = [0, 0]
        d = []
        uniq.each do |a_uniq, b_uniq|
          start_a, start_b = move_to_next_difference(text_a, text_b, a1, b1)
          # (a_uniq < a1 || b_uniq < b1) == true guarentees there is not a change (since we walked a1 and b1 to changes before this section, and at the end of each block)
          # a1 and b1 are always the lines right before the next change.

          next if a_uniq < start_a || b_uniq < start_b
          a1, b1 = [a_uniq + 1, b_uniq + 1]
          # we know a_uniq to be the next line which has a corresponding b_uniq. so a1 = last line of potential change (as does b1)
          end_a, end_b = move_to_prev_difference(text_a, text_b, start_a, start_b, a_uniq - 1, b_uniq - 1)
          d << assign_action(start_a, start_b, end_a, end_b)

        end

        d.compact
      end

      private

        def self.set_frequencies(freq, p, text, flag)
          text.each_with_index do |line, i|
            freq[line] ||= 0
            freq[line] += flag                # add 2 to the freq of line if its in text_a
            p[line] = i                    # set ap[line] to the line number
          end
        end

        def self.find_uniq_matches(text_a, text_b)
          uniq = [[text_a.length, text_b.length]]
          freq, ap, bp = [{}, {}, {}]

          set_frequencies(freq, ap, text_a, 2)
          set_frequencies(freq, bp, text_b, 3)

          freq.each do |line, x|
            if x == 5
              uniq << [ap[line], bp[line]]    # if the line was uniqely in both, push [line index in a, line index in b])
            end
          end
          uniq.sort!{|a, b| a[0] <=> b[0]}    # sort by the line in which the line was found in a
          uniq
        end

        def self.move_to_next_difference(text_a, text_b, a1, b1)
          # walk a1 and b1 to next change spot
          # and set a1 and b1 to be the first line where there is a change.
          while a1 < text_a.length && b1 < text_b.length
            if text_a[a1] != text_b[b1]
              break
            end
            a1 += 1
            b1 += 1
          end

          [a1, b1]
        end
        def self.move_to_prev_difference(text_a, text_b, a0, b0, a1, b1)
          # loop from a1 and b1's new positions down towards a0, b0.  stop when there is a change.  This gives the bounds of the change as [a0,a1] and [b0, b1]
          while a0 <= a1 && b0 <= b1
            break if text_a[a1] != text_b[b1]   # a change is found on lines a1 and b1.  break out of loop.
            a1 -= 1
            b1 -= 1
          end
          [a1, b1]
        end

        def self.assign_action(a0, b0, a1, b1)
          if a0 <= a1 && b0 <= b1 # for this change, the bounds are both 'normal'.  the beginning of the change is before the end.
            [:change, a0 + 1, a1 + 1, b0 + 1, b1 + 1]
          elsif a0 <= a1
            [:delete, a0 + 1, a1 + 1, b0 + 1, b0]
          elsif b0 <= b1
            [:add, a0 + 1, a0, b0 + 1, b1 + 1]
          else
            nil
          end
        end
    end
  end
end