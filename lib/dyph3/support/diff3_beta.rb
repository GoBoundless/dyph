module Dyph3
  module Support
    module Diff3Beta
      extend self
      # Three-way diff based on the GNU diff3.c by R. Smith.
      #   @param [in] left    Array of lines of left text.
      #   @param [in] base    Array of lines of base text.
      #   @param [in] right   Array of lines of right text.
      #   @returns Array of tuples containing diff results. The tuples consist of
      #        (cmd, loA, hiA, loB, hiB), where cmd is either one of
      #        :choose_left, :choose_right, :no_conflict_found, or :possible_conflict.
      def execute_diff(left, base, right, current_differ)
        DiffManager.new(left, base, right, current_differ).generate_change_codes.map do |change_code|
          diff_region = DiffRegion.new(change_code, left, right)
          diff_region.change_region
        end
      end
    end

    class DiffManager
      def initialize(left, base, right, current_differ)
        @left   = left
        @right  = right
        @base   = base
        @current_differ = current_differ
      end

      def generate_change_codes
        #[[action, base_lo, base_hi, side_lo, side_hi]...]
        left_diff  = @current_differ.diff(@base, @left) || []
        right_diff = @current_differ.diff(@base, @right) || []

        codes = []
        working_stacks =  { left: left_diff, right: right_diff }

        while working_stacks[:left].any? || working_stacks[:right].any?
          init_side, current_side = initialize_sides(left_diff, right_diff)

          result_stacks   = { left: [], right: [] }

          current_stack   = working_stacks[init_side]
          top             = current_stack.shift
          result_stacks[init_side] << top

          final_result, final_side = find_final_side(working_stacks, current_side, diff_2_result(top).base_hi, result_stacks)
          codes << ChangeCode.new(final_result, init_side, final_side)
        end

        codes
      end

      private
        def find_final_side(working_stacks, current_side, prev_hi, result_stacks)
          #current side can be :left or :right
          current_stack = working_stacks[current_side]
          if current_stack.empty? || (diff_2_result(current_stack.first).base_lo > prev_hi + 1)
             [result_stacks, toggle(current_side)]
          else
            top             = current_stack.shift
            diff2_result    = diff_2_result top
            result_stacks[current_side] << top

            if prev_hi < diff2_result.base_hi
              #if the last change goes too high, switch the side.
              find_final_side(working_stacks, toggle(current_side), diff2_result.base_hi, result_stacks)
            else
              find_final_side(working_stacks, current_side, prev_hi, result_stacks)
            end
          end
        end

        def diff_2_result(result)
           Diff2Result.new(*result)
        end

        def initialize_sides(left_diff, right_diff)
          init_side = if left_diff.empty?
            :right
          elsif right_diff.empty?
            :left
          else
            if diff_2_result(left_diff.first).base_lo <= diff_2_result(right_diff.first).base_lo
              :left
            else
              :right
            end
          end
          [init_side, toggle(init_side)]
        end

        def toggle(side)
          if side == :left
            :right
          else
            :left
          end
        end
    end

    ChangeCode = Struct.new(:result, :init_side, :final_side)
    Diff2Result = Struct.new(:code, :base_lo, :base_hi, :side_lo, :side_hi)

    class DiffRegion
      attr_reader :result, :init_side, :final_side

      def initialize(change_code, left, right)
        @left = left
        @right = right
        @result = change_code.result
        @init_side = change_code.init_side
        @final_side = change_code.final_side

        set_ranges
        set_result_fields
      end

      def overlap_lo
        result[init_side].first[1]
      end

      def overlap_hi
        result[final_side].last[2]
      end

      def get_hi_lo_ranges(side:)
        #diff_region: {:left=>[["c", 2, 2, 2, 2]], :right=>[["a", 3, 2, 3, 3]]}
        #lo:  lo offset
        #hi: inv_current_side's hi
        #side: which side we are currently checking
        left_lo, left_hi, right_lo, right_hi = [1,2,3,4] #indexes
        if !result[side].empty?
          [
            result[side].first[right_lo] - result[side].first[left_lo] + overlap_lo,
            result[side].last[right_hi] - result[side].last[left_hi] + overlap_hi
          ]
        else
          [overlap_lo, overlap_hi]
        end
      end

      def left_ranges
        get_hi_lo_ranges(side: :left)
      end

      def right_ranges
        get_hi_lo_ranges(side: :right)
      end

      def set_ranges
        @left_lo, @left_hi    = left_ranges
        @right_lo, @right_hi  = right_ranges
      end

      def set_result_fields
        if result[:left].empty?
          @change_type = :choose_right
        elsif result[:right].empty?
          @change_type = :choose_left
        elsif @left_hi - @left_lo != @right_hi - @right_lo
          @change_type = :possible_conflict
        else
          @change_type = :no_conflict_found
          (0 .. @left_hi - @left_lo).each do |d|
            (i0, i1) = [@left_lo + d - 1, @right_lo + d - 1]
            ok0 = (0 <= i0 && i0 < @left.length)
            ok1 = (0 <= i1 && i1 < @right.length)

            if (ok0 ^ ok1) || (ok0 && @left[i0] != @right[i1])
              @change_type = :possible_conflict
              break
            end
          end
        end
        @change_type
      end

      def change_region
        [@change_type, @left_lo, @left_hi, @right_lo, @right_hi, overlap_lo, overlap_hi]
      end
    end
  end
end