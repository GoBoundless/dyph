module Dyph3
  module Support

    class Diff3Beta
      def self.execute_diff(left, base, right, current_differ)
        Diff3Beta.new(left, base, right, current_differ).get_differences
      end

      def initialize(left, base, right, current_differ)
        @left   = left
        @right  = right
        @base   = base
        @current_differ = current_differ
      end

      def get_differences
        #[[action, base_lo, base_hi, side_lo, side_hi]...]
        left_diff  = @current_differ.diff(@base, @left).map { |r| Diff2Command.new(*r) }
        right_diff = @current_differ.diff(@base, @right).map { |r| Diff2Command.new(*r) }
        collapse_differences(DiffDoubleStack.new(left_diff, right_diff))
      end

      private
        Diff2Command = Struct.new(:code, :base_lo, :base_hi, :side_lo, :side_hi)

        def collapse_differences(double_stack, differences=[])
          if double_stack.finished?
            differences
          else
            result_stack   = DiffDoubleStack.new
            init_side = result_stack.initialize_sides double_stack.peek(:left), double_stack.peek(:right)

            top_diff   =  double_stack.pop(init_side)
            result_stack.push init_side, top_diff

            command_stacks, final_side = build_result_stack(double_stack, toggle(init_side), top_diff.base_hi, result_stack)
            differences << determine_differnce(command_stacks, init_side, final_side)

            collapse_differences(double_stack, differences)
          end
        end

        def build_result_stack(double_stack, current_side, prev_base_hi, result_stack)
          #current side can be :left or :right
          if stack_finished?(double_stack.peek(current_side), prev_base_hi)
            [result_stack, toggle(current_side)]
          else
            top_diff = double_stack.pop current_side
            result_stack.push current_side, top_diff

            if prev_base_hi < top_diff.base_hi
              #switch the current side and adjust the base_hi
              build_result_stack(double_stack, toggle(current_side), top_diff.base_hi, result_stack)
            else
              build_result_stack(double_stack, current_side, prev_base_hi, result_stack)
            end
          end
        end

        def stack_finished?(stack, prev_base_hi)
          stack.empty? || stack.first.base_lo > prev_base_hi + 1
        end

        def toggle(side)
          side == :left ? :right : :left
        end

        def determine_differnce(diff_double_stack, init_side, final_side)
          base_lo = diff_double_stack.get(init_side).first.base_lo
          base_hi = diff_double_stack.get(final_side).first.base_hi

          left_lo,  left_hi    = diffible_endpoints(diff_double_stack.get(:left), base_lo, base_hi)
          right_lo, right_hi   = diffible_endpoints(diff_double_stack.get(:right), base_lo, base_hi)

          #the endpoints are offset one, neet to account for that in getting subsets
          left_subset = @left[left_lo-1 .. left_hi]
          right_subset = @right[right_lo-1 .. right_hi]

          change_type = decide_action(diff_double_stack, left_subset, right_subset)
          [change_type, left_lo, left_hi, right_lo, right_hi, base_lo, base_hi]
        end

        def diffible_endpoints(command, base_lo, base_hi)
          if command.any?
            lo = command.first.side_lo - command.first.base_lo +  base_lo
            hi = command.last.side_hi  - command.last.base_hi  + base_hi
            [lo, hi]
          else
            [base_lo,  base_hi]
          end
        end

        def decide_action(diff_double_stack, left_subset, right_subset)
          #adjust because the ranges are 1 indexed
          if diff_double_stack.empty?(:left)
            :choose_right
          elsif diff_double_stack.empty?(:right)
            :choose_left
          else
            if left_subset.zip(right_subset).any? { |x, y| x != y}
              :possible_conflict
            else
              :no_conflict_found
            end
          end
        end
    end

    class DiffDoubleStack
      def initialize(left=[], right=[])
        @diffs = { left: left, right: right }
      end

      def pop(side)
        @diffs[side].shift
      end

      def peek(side)
        @diffs[side]
      end

      def finished?
        empty?(:left) && empty?(:right)
      end

      def push(side, val)
        @diffs[side] << val
      end

      def get(side)
        @diffs[side]
      end

      def empty?(side)
        @diffs[side].empty?
      end

      def initialize_sides(left, right)
        @current_side = if left.empty?
          :right
        elsif right.empty?
          :left
        else
          #choose the lowest side relative to base
          left.first.base_lo <= right.first.base_lo ? :left : :right
        end
     end
    end

  end
end