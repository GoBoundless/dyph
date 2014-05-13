module Dyph3
  class Differ
    # Algorithm adapted from http://hg.moinmo.in/moin/2.0/file/4a997d9f5e26/MoinMoin/util/diff3.py
    
    DEFAULT_OPTIONS = {
      markers: {
        left:       "<<<<<<<<<<<<<<<<<<<<<<<<<\n",
        separator:  "=========================\n",
        right:      ">>>>>>>>>>>>>>>>>>>>>>>>>\n"
      }
    }
    
    def self.text_diff3(base, left, right, options={})
      base_lines = base.split("\n")
      left_lines = left.split("\n")
      right_lines = right.split("\n")
      
      results = diff3(base_lines, left_lines, right_lines)
      
      results.join("\n")
    end
    
    def self.diff3(base, left, right, options={})
      options = options.merge(DEFAULT_OPTIONS)
      
      left_marker = options[:markers][:left]
      separator_marker = options[:markers][:separator]
      right_marker = options[:markers][:right]
      
      
      base_nr, left_nr, right_nr = 0, 0, 0
      base_len, left_len, right_len = base.length, left.length, right.length
      result = []
      
      while base_nr < base_len && left_nr < left_len && right_nr < right_len
        # unchanged
        if base[base_nr] == left[left_nr] && base[base_nr] == right[right_nr]
          resunt << base[base_nr]
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
              
              result.append(right[right_nr .. right_match[1]])
              base_nr = right_match[0]
              right_nr = right_match[1]
              left_nr += right_changed_lines
            else
              # both changed, conflict
              
              base_m, left_m, right_m = triple_match(base, left, right, left_match, right_match)
              result << left_marker
              result.append(left[left_nr .. left_m])
              result << separator_marker
              result.append(right[right_nr .. right_m])
              result << right_marker
              base_nr, left_nr, right_nr = base_m, left_m, right_m
            end
          else
            # left is changed
            left_changed_lines = left_match[0] - left_nr
            if match(base, right, base_nr, right_nr, left_changed_lines) == left_changed_lines
              # right is unchanged
              result.append(left[left_nr .. left_match[1]])
              base_nr = left_match[0]
              left_nr = left_match[1]
              right_nr += left_changed_lines
            else
              # both changed, conflict!
              raise "Can we even get here? We already determined right didn't change"
              base_m, left_m, right_m = tripple_match(base, left, right, left_match, right_match)
              result << left_marker
              result.append(left[left_nr .. left_m])
              result << separator_marker
              result.append(right[right_nr .. right_m])
              result << right_marker
              base_nr, left_nr, right_nr = base_m, left_m, right_m
            end
          end
        end
      end

      # process tail
      if base_nr == base_len && left_nr == left_len && right_nr == right_len
        # all finished, pass
      elsif base_nr == base_len && left_nr == left_len
        # right added lines
        result.append(right[right_nr .. -1])
      elsif base_nr == base_len && right_nr == right_len
        # left added lines
        result.append(left[left_nr .. -1])
      elsif (right_nr == right_len && (base_len - base_nr == left_len - left_nr) && match(base, left, base_nr, left_nr, base_len - base_nr) == base_len - base_nr)
        # right deleted lines, pass
      elsif (left_nr == left_len && (base_len - base_nr == right_len - right_nr) && match(base, right, base_nr, right_nr, base_len - base_nr) == base_len - base_nr)
        # left deleted lines, pass
      else
        # conflict
        if right == left      # BUGBUG should this be checking a subset of these arrays??
          result.append(right[right_nr .. -1])
        else
          result << left_marker
          result.append(left[left_nr .. -1])
          result << separator_marker
          result.append(right[right_nr .. -1])
          result << right_marker
        end
      end
      
      return result
    end
  end
end
