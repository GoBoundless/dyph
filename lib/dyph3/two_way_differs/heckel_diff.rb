module Dyph3
  module TwoWayDiffers
    class HeckelDiff
      # Two-way diff based on the algorithm by P. Heckel.
      # @param [in] text_a Array of lines of first text.
      # @param [in] text_b Array of lines of second text.
      # @returns Array of arrays [cmd, our_lo, our_hi, their_lo, their_hi]
      def self.diff(text_a, text_b)
        d = []
        uniq = [[text_a.length, text_b.length]]
        #start building up uniq, the set of lines which appear exactly once in each text
        freq, ap, bp = [{}, {}, {}]
        text_a.each_with_index do |line, i|
          freq[line] ||= 0
          freq[line] += 2                   # add 2 to the freq of line if its in text_a
          ap  [line] = i                    # set ap[line] to the line number
        end

        text_b.each_with_index do |line, i|
          freq[line] ||= 0
          freq[line] += 3                   # add 3 to the freq of line if its in text_b
          bp  [line] = i                    # set bp[line] to the line number
        end

        freq.each do |line, x|
          if x == 5
            uniq << [ap[line], bp[line]]    # if the line was uniqely in both, push [line index in a, line index in b])
          end
        end
        freq, ap, bp = [{}, {}, {}]
        uniq.sort!{|a, b| a[0] <=> b[0]}    # sort by the line in which the line was found in a
        a1, b1 = [0, 0]
        # set a1 and b1 to be the first line where there is a change.
        while a1 < text_a.length && b1 < text_b.length
          if text_a[a1] != text_b[b1]
            break
          end
          a1 += 1
          b1 += 1
        end
        # start with a1, b1 being the lines before the first change.
        # for each pair of lines in uniq which definitely match eachother:
        uniq.each do |a_uniq, b_uniq|
          # (a_uniq < a1 || b_uniq < b1) == true guarentees there is not a change (since we walked a1 and b1 to changes before this section, and at the end of each block)
          # a1 and b1 are always the lines right before the next change.
          if a_uniq < a1 || b_uniq < b1
            next
          end
          # a0, b0 are the last agreeing lines before a change.
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

          if a0 <= a1 && b0 <= b1 # for this change, the bounds are both 'normal'.  the beginning of the change is before the end.
            d << ['c', a0 + 1, a1 + 1, b0 + 1, b1 + 1]
          elsif a0 <= a1
            d << ['d', a0 + 1, a1 + 1, b0 + 1, b0]
          elsif b0 <= b1
            d << ['a', a0 + 1, a0, b0 + 1, b1 + 1]
          end

          #set a1 and b1 to be the words after the matching uniq word
          a1, b1 = [a_uniq + 1, b_uniq + 1]

          # walk a1 and b1 to next change spot
          while a1 < text_a.length && b1 < text_b.length
            if text_a[a1] != text_b[b1]
              break
            end
            a1 += 1
            b1 += 1
          end
        end
        d
      end
    end
  end
end