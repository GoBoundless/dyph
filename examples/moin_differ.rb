module Dyph3
  class Differ
    # Algorithm adapted from http://hg.moinmo.in/moin/2.0/file/4a997d9f5e26/MoinMoin/util/diff3.py

    DEFAULT_OPTIONS = {
      markers: {
        left:       "<<<<<<<<<<<<<<<<<<<<<<<<<",
        separator:  "=========================",
        right:      ">>>>>>>>>>>>>>>>>>>>>>>>>"
      }
    }

    def self.text_diff3(base, left, right, options={})
      base_lines = base.split("\n")
      left_lines = left.split("\n")
      right_lines = right.split("\n")

      results_hash = diff3(base_lines, left_lines, right_lines, options)
      { result: results_hash[:result].join("\n"), conflicted: results_hash[:conflicted] }
    end

    def self.diff3(base, left, right, options={})
      conflicted = false
      options = DEFAULT_OPTIONS.merge(options)

      left_marker = options[:markers][:left]
      separator_marker = options[:markers][:separator]
      right_marker = options[:markers][:right]


      base_nr, left_nr, right_nr = 0, 0, 0
      base_len, left_len, right_len = base.length, left.length, right.length
      result = []

      while base_nr < base_len && left_nr < left_len && right_nr < right_len
        # unchanged
        if base[base_nr] == left[left_nr] && base[base_nr] == right[right_nr]
          result << base[base_nr]
          base_nr += 1
          left_nr += 1
          right_nr += 1
        else
          right_match = find_match(base, right, base_nr, right_nr)
          left_match = find_match(base, left, base_nr, left_nr)

          if right_match[0] != base_nr || right_match[1] != right_nr
            # right is changed

            right_changed_lines = right_match[0] - base_nr

            if match(base, left, base_nr, left_nr, right_changed_lines) == right_changed_lines
              # left is unchanged

              result.concat(right[right_nr ... right_match[1]])
              base_nr = right_match[0]
              right_nr = right_match[1]
              left_nr += right_changed_lines
            else
              # both changed, conflict
              base_m, left_m, right_m = triple_match(base, left, right, left_match, right_match)
              left_change = left[left_nr ... left_m]
              right_change = right[right_nr ... right_m]
              if left_change == right_change
                #both changed but have the same change
                result.concat(left_change)
              else
                result << left_marker
                result.concat(left_change)
                result << separator_marker
                result.concat(right_change)
                result << right_marker
                conflicted = true
              end
              base_nr, left_nr, right_nr = base_m, left_m, right_m
            end
          else
            # left is changed
            left_changed_lines = left_match[0] - left_nr
            if match(base, right, base_nr, right_nr, left_changed_lines) == left_changed_lines
              # right is unchanged
              result.concat(left[left_nr ... left_match[1]])
              base_nr = left_match[0]
              left_nr = left_match[1]
              right_nr += left_changed_lines
            else
              # both changed, conflict!
              raise "Can we even get here? We already determined right didn't change"
              base_m, left_m, right_m = triple_match(base, left, right, left_match, right_match)
              result << left_marker
              result.concat(left[left_nr ... left_m])
              result << separator_marker
              result.concat(right[right_nr ... right_m])
              result << right_marker
              base_nr, left_nr, right_nr = base_m, left_m, right_m
              conflicted = true
            end
          end
        end
      end

      # process tail
      if base_nr == base_len && left_nr == left_len && right_nr == right_len
        # all finished, pass
      elsif base_nr == base_len && left_nr == left_len
        # right added lines
        result.concat(right[right_nr .. -1])
      elsif base_nr == base_len && right_nr == right_len
        # left added lines
        result.concat(left[left_nr .. -1])
      elsif (right_nr == right_len && (base_len - base_nr == left_len - left_nr) && match(base, left, base_nr, left_nr, base_len - base_nr) == base_len - base_nr)
        # right deleted lines, pass
      elsif (left_nr == left_len && (base_len - base_nr == right_len - right_nr) && match(base, right, base_nr, right_nr, base_len - base_nr) == base_len - base_nr)
        # left deleted lines, pass
      else
        # conflict
        if right == left      # BUGBUG should this be checking a subset of these arrays??
          result.concat(right[right_nr .. -1])
        else
          result << left_marker
          result.concat(left[left_nr .. -1])
          result << separator_marker
          result.concat(right[right_nr .. -1])
          result << right_marker
          conflicted = true
        end
      end

      return { result: result, conflicted: conflicted }
    end

    private
      # find next matching pattern unchanged in both left and right
      # return the position in all three lists
      def self.triple_match(base, left, right, left_match, right_match)
        while true
          difference = right_match[0] - left_match[0]
          if difference > 0
            # right changed more lines

            match_len = match(base, left, left_match[0], left_match[1], difference)
            if match_len == difference
              return right_match[0], left_match[1] + difference, right_match[1]
            else
              left_match = find_match(base, left, left_match[0] + match_len, left_match[1] + match_len)
            end
          elsif difference < 0
            # left changed more lines

            difference = -1 * difference
            match_len = match(base, right, right_match[0], right_match[1], difference)
            if match_len == difference
              return [left_match[0], left_match[1], right_match[0] + difference]
            else
              right_match = find_match(base, right, right_match[0] + match_len, right_match[1] + match_len)
            end
          else
            # both conflicts change same number of lines or no match till the end

            return right_match[0], left_match[1], right_match[1]
          end
        end
      end

      # return the number matching items after the given positions
      # maximum maxcount lines are are processed
      def self.match(list1, list2, nr1, nr2, maxcount=3)
        i = 0
        len1 = list1.length
        len2 = list2.length
        while nr1 < len1 && nr2 < len2 && list1[nr1] == list2[nr2]
          nr1 += 1
          nr2 += 1
          i += 1
          if i >= maxcount && maxcount > 0
            break
          end
        end
        return i
      end

      # searches next matching pattern with length mincount
      # if no pattern is found len of the both lists is returned
      def self.find_match(list1, list2, nr1, nr2, mincount=3)
        len1 = list1.length
        len2 = list2.length
        hit1 = nil
        hit2 = nil
        idx1 = nr1
        idx2 = nr2

        while (idx1 < len1) || (idx2 < len2)
          i = nr1
          while i <= idx1
            hit_count = match(list1, list2, i, idx2, mincount)
            if hit_count >= mincount
              hit1 = [i, idx2]
              break
            end
            i += 1
          end

          i = nr2
          while i < idx2
            hit_count = match(list1, list2, idx1, i, mincount)
            if hit_count >= mincount
              hit2 = [idx1, i]
              break
            end
            i += 1
          end

          break if hit1 || hit2
          idx1 += 1 if idx1 < len1
          idx2 += 1 if idx2 < len2
        end

        if hit1 && hit2
          # XXX which one?
          return hit1
        elsif hit1
          return hit1
        elsif hit2
          return hit2
        else
          return [len1, len2]
        end
      end
  end
end
