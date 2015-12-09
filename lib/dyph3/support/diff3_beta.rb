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

    ChangeCode = Struct.new(:result, :init_side, :final_side)
    Diff2Result = Struct.new(:code, :base_lo, :base_hi, :side_lo, :side_hi)

    class DiffManager
      def initialize(left, base, right, current_differ)
        @left   = left
        @right  = right
        @base   = base
        @current_differ = current_differ
      end

      def generate_change_codes
        #[[action, base_lo, base_hi, side_lo, side_hi]...]
        left_diff  = @current_differ.diff(@base, @left).map { |r| Diff2Result.new(*r) } || []
        right_diff = @current_differ.diff(@base, @right).map { |r| Diff2Result.new(*r) } || []
        codes = []
        working_stacks =  { left: left_diff, right: right_diff }

        while working_stacks[:left].any? || working_stacks[:right].any?
          init_side, current_side = initialize_sides(left_diff, right_diff)
          result_stacks   = { left: [], right: [] }

          top_code   = working_stacks[init_side].shift
          result_stacks[init_side] << top_code

          final_result, final_side = find_final_side(working_stacks, current_side, top_code.base_hi, result_stacks)
          codes << ChangeCode.new(final_result, init_side, final_side)
        end
        codes
      end

      private

        def find_final_side(working_stacks, current_side, prev_base_hi, result_stacks)
          #current side can be :left or :right
          if stack_finished?(working_stacks[current_side], prev_base_hi)
            [result_stacks, toggle(current_side)]
          else
            top_code = working_stacks[current_side].shift
            result_stacks[current_side] << top_code

            if prev_base_hi < top_code.base_hi
              #switch the current side and adjust the base_hi
              find_final_side(working_stacks, toggle(current_side), top_code.base_hi, result_stacks)
            else
              find_final_side(working_stacks, current_side, prev_base_hi, result_stacks)
            end
          end
        end

        def stack_finished?(stack, prev_base_hi)
          stack.empty? || stack.first.base_lo > prev_base_hi + 1
        end

        def initialize_sides(left_diff, right_diff)
          init_side = if left_diff.empty?
            :right
          elsif right_diff.empty?
            :left
          else
            #choose the lowest side relative to base
            if left_diff.first.base_lo <= right_diff.first.base_lo
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

    class DiffRegion
      attr_reader :result, :init_side, :final_side

      def initialize(change_code, left, right)
        @left         = left
        @right        = right
        @result       = change_code.result
        @init_side    = change_code.init_side
        @final_side   = change_code.final_side
        set_ranges
        set_change_region
      end

      def change_region
        [@change_type, @left_lo, @left_hi, @right_lo, @right_hi, overlap_lo, overlap_hi]
      end

      private

        def overlap_lo
          result[init_side].first.base_lo
        end

        def overlap_hi
          result[final_side].first.base_hi
        end

        def get_hi_lo_ranges(side:)
          #diff_region: {:left=>[["c", 2, 2, 2, 2]], :right=>[["a", 3, 2, 3, 3]]}
          #lo:  lo offset
          #hi: inv_current_side's hi
          #side: which side we are currently checking
          if !result[side].empty?
            [
              result[side].first.side_lo - result[side].first.base_lo + overlap_lo,
              result[side].last.side_hi  - result[side].last.base_hi  + overlap_hi
            ]
          else
            [overlap_lo, overlap_hi]
          end
        end

        def set_ranges
          @left_lo, @left_hi    = get_hi_lo_ranges(side: :left)
          @right_lo, @right_hi  = get_hi_lo_ranges(side: :right)
        end

        def set_change_region
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
              #what is this????
              if (ok0 ^ ok1) || (ok0 && @left[i0] != @right[i1])
                @change_type = :possible_conflict
                break
              end
            end
          end
          @change_type
        end
    end
  end
end