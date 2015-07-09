module Dyph3
  module TwoWayDiffers
    class OriginalHeckelDiff
      # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html


      # Two-way diff based on the algorithm by P. Heckel.
      # @param [in] text_a Array of lines of first text.
      # @param [in] text_b Array of lines of second text.
      # @returns TODO
      def self.diff(text_a, text_b)
        d    = []
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

        # set a1 and b1 to be the first line where there is a conflict.
        while a1 < text_a.length && b1 < text_b.length
          if text_a[a1] != text_b[b1]
            break
          end
          a1 += 1
          b1 += 1
        end

        # start with a1, b1 being the lines before the first conflict.
        # for each pair of lines in uniq which definitely match eachother:
        uniq.each do |a_uniq, b_uniq|
          # (a_uniq < a1 || b_uniq < b1) == true guarentees there is not a conflict (since we walked a1 and b1 to conflicts before this section, and at the end of each block)
          # a1 and b1 are always the lines right before the next conflict.
          if a_uniq < a1 || b_uniq < b1
            next
          end
          # a0, b0 are the last agreeing lines before a conflict.
          a0, b0 = [a1, b1]
          # we know a_uniq to be the next line which has a corresponding b_uniq. so a1 = last line of potential conflict (as does b1)
          a1, b1 = [a_uniq - 1, b_uniq - 1]
          # loop from a1 and b1's new positions down towards a0, b0.  stop when there is a conflict.  This gives the bounds of the conflict as [a0,a1] and [b0, b1]
          while a0 <= a1 && b0 <= b1
            if text_a[a1] != text_b[b1]   # a conflict is found on lines a1 and b1.  break out of loop.
              break
            end
            a1 -= 1
            b1 -= 1
          end

          d = add_conflict(d, a0, a1, b0, b1)
          
          #set a1 and b1 to be the words after the matching uniq word
          a1, b1 = [a_uniq + 1, b_uniq + 1]

          # walk a1 and b1 to next conflict spot
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

      private
        def self.invert_target(target)
          if target == :your
            :their
          else
            :your
          end
        end

        # called only in cases where there may be a conflict
        def self._conflict_range(text3, chunk_desc, res)
          text_a = [] # conflicting lines in theirtext
          (chunk_desc[3] .. chunk_desc[4]).each do |i|                   # inclusive(..)
            text_a << text3[1][i - 1]
          end
          text_b = [] # conflicting lines in yourtext
          (chunk_desc[1] .. chunk_desc[2]).each do |i|                   # inclusive(..)
            text_b << text3[0][i - 1]
          end
          d = diff(text_a, text_b)
          if !_assoc_range(d, 'c').nil? && chunk_desc[5] <= chunk_desc[6]
            conflict = {type: :conflict}
            conflict[:ours] = accumulate_lines(chunk_desc[1], chunk_desc[2], text3[0])
            conflict[:base] = accumulate_lines(chunk_desc[5], chunk_desc[6], text3[2])
            conflict[:theirs] = accumulate_lines(chunk_desc[3], chunk_desc[4], text3[1])
            res << conflict
            return res
          end

          ia = 1

          d.each do |r2|
            if ia > r2[1]
              non_conflict = {type: :non_conflict}
              non_conflict[:text] = accumulate_lines(ia, r2[1]+1, text_a)
              res << non_conflict
            end
            conflict = {}
            if r2[0] == 'c'
              conflict[:type] =  :conflict
              conflict[:ours] = accumulate_lines(r2[3], r2[4], text_b)
              conflict[:theirs] = accumulate_lines(r2[1], r2[2], text_a)
            elsif r2[0] == 'a'
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
          if chunk_desc[0] == '0'
            # 0 flag means choose yourtext.  put lines chunk_desc[1] .. chunk_desc[2] into the resulting body.
            temp_text = accumulate_lines(chunk_desc[1], chunk_desc[2], text3[0])
            res << {type: :non_conflict, text: temp_text}
          elsif chunk_desc[0] != 'A'
            # A flag means choose theirtext.  put lines chunk_desc[3] to chunk_desc[4] into the resulting body.
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

        # take the corresponding ranges in yourtext lo0...hi0
        # and in theirtext lo1...hi1.
        #
        #   yourtext     ...L!!!!!!!!!!!!!!!!!!!!!!!!!!!!H..
        #   d2[:your]       222    222222222
        #   origtext     ..00!1111!000!!00!111111..
        #   d2[:their]        222222   22  2222222
        #  theirtext          ..L!!!!!!!!!!!!!!!!H..
        def self.determine_ranges(r2, chunk_desc, lo2, hi2)
          if !r2[:your].empty?
            your_lo = r2[:your][ 0][3] - r2[:your][ 0][1] + lo2
            your_hi = r2[:your][-1][4] - r2[:your][-1][2] + hi2
          else
            your_lo = chunk_desc[2] - chunk_desc[6] + lo2
            your_hi0 = chunk_desc[2] - chunk_desc[6] + hi2
          end
          if !r2[:their].empty?
            their_lo = r2[:their][ 0][3] - r2[:their][ 0][1] + lo2
            their_hi = r2[:their][-1][4] - r2[:their][-1][2] + hi2
          else
            their_lo = chunk_desc[4] - chunk_desc[6] + lo2
            their_hi = chunk_desc[4] - chunk_desc[6] + hi2
          end
          [your_lo, your_hi, their_lo, their_hi]
        end


        def self.determine_conflict_type(r2, yourtext, theirtext, your_lo, your_hi, their_lo, their_hi)
          # detect type of changes
          if r2[:your].empty?
            cmd = '1'
          elsif r2[:their].empty?
            cmd = '0'
          elsif your_hi - your_lo != their_hi - their_lo
            cmd = 'A'
          else
            cmd = '2'
            (0 .. your_hi - your_lo).each do |d|
              (i0, i1) = [your_lo + d - 1, their_lo + d - 1]
              ok0 = (0 <= i0 && i0 < yourtext.length)
              ok1 = (0 <= i1 && i1 < theirtext.length)
              if (ok0 ^ ok1) || (ok0 && yourtext[i0] != theirtext[i1])
                cmd = 'A'
                break
              end
            end
          end
          cmd
        end

        # given the calculated bounds of the 2 way diff, create the proper conflict type and add it to the queue.
        def self.add_conflict(d, a0, a1, b0, b1)
          if a0 <= a1 && b0 <= b1 # for this conflict, the bounds are both 'normal'.  the beginning of the conflict is before the end.
            d << ['c', a0 + 1, a1 + 1, b0 + 1, b1 + 1]
          elsif a0 <= a1
            d << ['d', a0 + 1, a1 + 1, b0 + 1, b0]
          elsif b0 <= b1
            d << ['a', a0 + 1, a0, b0 + 1, b1 + 1]
          end
          d
        end

        def self.set_targets(d2)
          #run out of conflicts in :your queue
          if d2[:your].empty?
            i_target = :their
          else
            #run out of conflicts in :their queue
            if d2[:their].empty?
              i_target = :your
            else
              #there are conflicts in both queues. let the target be the earlier one.
              if d2[:your][0][1] <= d2[:their][0][1]
                i_target = :your
              else
                i_target = :their
              end
            end
          end

          j_target = i_target
          k_target = invert_target(i_target) # k_target is opposite of i and j

          [i_target, j_target, k_target]
        end

        # @param [in] conflicts
        # @returns the list of conflicts with contiguous parts merged if they are non_conflicts
        def self.merge_non_conflicts(res, i = 0)
          if i == res.length - 1
            return res
          elsif res[i][:type] == :non_conflict && res[i+1][:type] == :non_conflict
            res[i][:text] += "\n" unless res[i][:text][-1] == "\n"
            res[i][:text] += res[i+1][:text]
            res.delete_at(i+1)
            merge_non_conflicts(res, i)
          else
            merge_non_conflicts(res, i+1)
          end
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
    end
  end
end