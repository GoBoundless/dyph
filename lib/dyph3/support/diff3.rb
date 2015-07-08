module Dyph3
  module Support
    module Diff3
      extend self
      # Three-way diff based on the GNU diff3.c by R. Smith.
      #   @param [in] left    Array of lines of left text.
      #   @param [in] base    Array of lines of base text.
      #   @param [in] right   Array of lines of right text.
      #   @returns Array of tuples containing diff results. The tuples consist of
      #        (cmd, loA, hiA, loB, hiB), where cmd is either one of
      #        :choose_left, :choose_right, :no_conflict_found, or :possible_conflict.
      def execute_diff(left, base, right, current_differ)

        # diff result => [(cmd, loA, hiA, loB, hiB), ..]
        d2 = {
          left: current_differ.diff(base, left), # queue of conflicts with left
          right: current_differ.diff(base, right) # queue of conflicts with right
        }

        result_diff3 = []

        # continue iterating while there are still conflicts.  goal is to get a set of 3conflicts (cmd, loA, hiA, loB, hiB)
        while d2[:left].length > 0 || d2[:right].length > 0
          r2 = { left: [], right: [] }
          #warning: this mutates r2 d2

          base_lo, base_hi = determine_continual_change_range_in_base(r2, d2)

          left_lo, left_hi    = get_hi_lo_ranges(r2, base_lo, base_hi, whose: :left)
          right_lo, right_hi  = get_hi_lo_ranges(r2, base_lo, base_hi, whose: :right)


          change_type = determine_change_type(r2, left, right, left_lo, left_hi, right_lo, right_hi)

          result_diff3 << [change_type, left_lo, left_hi, right_lo, right_hi, base_lo, base_hi]
        end

        result_diff3
      end

      private
        def determine_continual_change_range_in_base(r2, d2)
          i_target, j_target, k_target = set_targets(d2)
          # simultaneously consider all changes that overlap within a region. So, attempt to resolve
          # a single conflict from 'left' or 'right', but then must also consider all overlapping changes from the other set.
          hi = d2[j_target][0][2] #sets the limit as to the max line this conflict will consider

          r2[j_target] << d2[j_target].shift #set r2[j_target] to be the diff from j_target we are considering
          while d2[k_target].length > 0 && (d2[k_target][0][1] <= hi + 1) #if there are still changes in k_target and lo_k <= hi_j +1

            hi_k = d2[k_target][0][2]
            r2[k_target] << d2[k_target].shift # continue to put all overlapping changes with k_target onto r2[k_target]
            if hi < hi_k
              hi = hi_k #if the last conflict goes too high, switch the target.

              j_target = k_target
              k_target = invert_target(k_target)
            end
          end

          lo2 = r2[i_target][ 0][1]
          hi2 = r2[j_target][-1][2]
          [lo2, hi2]
        end

        def determine_change_type(r2, left, right, left_lo, left_hi, right_lo, right_hi)
          if r2[:left].empty?
            cmd = :choose_right
          elsif r2[:right].empty?
            cmd = :choose_left
          elsif left_hi - left_lo != right_hi - right_lo
            cmd = :possible_conflict
          else

            cmd = :no_conflict_found
            (0 .. left_hi - left_lo).each do |d|
              (i0, i1) = [left_lo + d - 1, right_lo + d - 1]
              ok0 = (0 <= i0 && i0 < left.length)
              ok1 = (0 <= i1 && i1 < right.length)

              if (ok0 ^ ok1) || (ok0 && left[i0] != right[i1])
                cmd = :possible_conflict
                break
              end
            end
          end
          cmd
        end

        def set_targets(d2)
          #run out of conflicts in :left queue
          if d2[:left].empty?
            i_target = :right
          else
            #run out of conflicts in :right queue
            if d2[:right].empty?
              i_target = :left
            else
              #there are conflicts in both queues. let the target be the earlier one.
              if d2[:left][0][1] <= d2[:right][0][1]
                i_target = :left
              else
                i_target = :right
              end
            end
          end

          j_target = i_target
          k_target = invert_target(i_target) # k_target is opposite of i and j

          [i_target, j_target, k_target]
        end

        def invert_target(target)
          if target == :left
            :right
          else
            :left
          end
        end

        def get_hi_lo_ranges(r2, base_lo, base_hi, whose:)
          #r2: {:left=>[["c", 2, 2, 2, 2]], :right=>[["a", 3, 2, 3, 3]]}
          #lo:  lo offset
          #hi: j_target's hi
          #whose: which target we are currently checking
          left_lo, left_hi, right_lo, right_hi = [1,2,3,4] #indexes
          if !r2[whose].empty?
            [
              r2[whose].first[right_lo] - r2[whose].first[left_lo] + base_lo,
              r2[whose].last[right_hi] - r2[whose].last[left_hi] + base_hi
            ]
          else
            [base_lo, base_hi]
          end
        end
    end
  end
end