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
          lo_a, lo_b = move_to_next_difference(text_a, text_b, a1, b1)
          a1, b1 = [a_uniq + 1, b_uniq + 1]

          # (a_uniq < a1 || b_uniq < b1) == true guarentees there is not a change (since we walked a1 and b1 to changes before this section, and at the end of each block)
          # a1 and b1 are always the lines right before the next change.
          next if a_uniq < lo_a || b_uniq < lo_b

          # we know a_uniq to be the next line which has a corresponding b_uniq. so a1 = last line of potential change (as does b1)
          hi_a, hi_b = move_to_prev_difference(text_a, text_b, lo_a, lo_b, a_uniq - 1, b_uniq - 1)
          d << Dyph3::Support::AssignAction.get_action(lo_a: lo_a, lo_b: lo_b, hi_a: hi_a, hi_b: hi_b)
        end

        d.compact
      end

      private
        def self.set_frequencies(freq, p, text, flag)
          text.each_with_index do |line, i|
            freq[line] ||= {}
            freq[line][flag] ||= 0
            freq[line][flag] += 1
            p[line] = i
          end
        end

        def self.find_uniq_matches(text_a, text_b)
          uniq = [[text_a.length, text_b.length]]
          freq, ap, bp = [{}, {}, {}]
          
          #this set_frequencies assigns and increments a flag
          #that indicates if the text is unique
          # 5 (2 + 3) means it is in each exactly once
          set_frequencies(freq, ap, text_a, :a_count)
          set_frequencies(freq, bp, text_b, :b_count)

          freq.each do |line, x|
            if x[:a_count] == 1 && x[:b_count] == 1
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
    end
  end
end