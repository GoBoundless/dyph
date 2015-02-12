module Dyph3
  module Support
    class Diff3
      # Three-way diff based on the GNU diff3.c by R. Smith.
      #   @param [in] left    Array of lines of your text.
      #   @param [in] origtext    Array of lines of base text.
      #   @param [in] right   Array of lines of their text.
      #   @returns Array of tuples containing diff results. The tuples consist of
      #        (cmd, loA, hiA, loB, hiB), where cmd is either one of
      #        :choose_left, :choose_right, :no_conflict_found, or :possible_conflict.
      def self.execute_diff(left, origtext, right, current_differ)
        # diff result => [(cmd, loA, hiA, loB, hiB), ..]
        d2 = {
          your: current_differ.diff(origtext, left), # queue of conflicts with your
          their: current_differ.diff(origtext, right) # queue of conflicts with their
        }

        result_diff3 = []

        # continue iterating while there are still conflicts.  goal is to get a set of 3conflicts (cmd, loA, hiA, loB, hiB)
        while d2[:your].length > 0 || d2[:their].length > 0

          #warning: this murates r2 d2
          r2 = { your: [], their: [] }

          base_lo, base_hi = determine_continual_change_range_in_base(r2, d2)

          your_lo, your_hi    = get_hi_lo_ranges(r2, base_lo, base_hi, whose: :your)
          their_lo, their_hi  = get_hi_lo_ranges(r2, base_lo, base_hi, whose: :their)

          change_type = determine_change_type(r2, left, right, your_lo, your_hi, their_lo, their_hi)

          result_diff3 << [change_type, your_lo, your_hi, their_lo, their_hi, base_lo, base_hi]
        end

        result_diff3
      end

      private
        def self.determine_continual_change_range_in_base(r2, d2)
          i_target, j_target, k_target = set_targets(d2)
          # simultaneously consider all changes that overlap within a region. So, attempt to resolve
          # a single conflict from 'your' or 'their', but then must also consider all overlapping changes from the other set.
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

        def self.determine_change_type(r2, left, right, your_lo, your_hi, their_lo, their_hi)
          if r2[:your].empty?
            cmd = :choose_right
          elsif r2[:their].empty?
            cmd = :choose_left
          elsif your_hi - your_lo != their_hi - their_lo
            cmd = :possible_conflict
          else
            cmd = :no_conflict_found
            (0 .. your_hi - your_lo).each do |d|
              (i0, i1) = [your_lo + d - 1, their_lo + d - 1]
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

        def self.invert_target(target)
          if target == :your
            :their
          else
            :your
          end
        end

        def self.get_hi_lo_ranges(r2, base_lo, base_hi, whose:)
          #r2: {:your=>[["c", 2, 2, 2, 2]], :their=>[["a", 3, 2, 3, 3]]}
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