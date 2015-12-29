module Dyph3
  module Support

    class Diff3
      def self.execute_diff(left, base, right, diff2)
        Diff3.new(left, base, right, diff2).get_differences
      end

      def initialize(left, base, right, diff2)
        @left   = left
        @right  = right
        @base   = base
        @diff2 = diff2
      end

      def get_differences
        #[[action, base_lo, base_hi, side_lo, side_hi]...]
        left_diff  = @diff2.diff(@base, @left).map { |r| Diff2Command.new(*r) }
        right_diff = @diff2.diff(@base, @right).map { |r| Diff2Command.new(*r) }
        collapse_differences(DiffDoubleQueue.new(left_diff, right_diff))
      end

      Diff2Command = Struct.new(:code, :base_lo, :base_hi, :side_lo, :side_hi)

      private

        def collapse_differences(diffs_queue, differences=[])
          if diffs_queue.finished?
            differences
          else
            result_queue   = DiffDoubleQueue.new
            init_side =  diffs_queue.choose_side
            top_diff   =  diffs_queue.dequeue

            result_queue.enqueue(init_side, top_diff)

            diffs_queue.switch_sides
            build_result_queue(diffs_queue, top_diff.base_hi, result_queue)

            differences << determine_differnce(result_queue, init_side, diffs_queue.switch_sides)
            collapse_differences(diffs_queue, differences)
          end
        end

        def build_result_queue(diffs_queue, prev_base_hi, result_queue)
          #current side can be :left or :right
          if queue_finished?(diffs_queue.peek, prev_base_hi)
            result_queue
          else
            top_diff = diffs_queue.dequeue
            result_queue.enqueue(diffs_queue.current_side, top_diff)

            if prev_base_hi < top_diff.base_hi
              #switch the current side and adjust the base_hi
              diffs_queue.switch_sides
              build_result_queue(diffs_queue, top_diff.base_hi, result_queue)
            else
              build_result_queue(diffs_queue, prev_base_hi, result_queue)
            end
          end
        end

        def queue_finished?(queue, prev_base_hi)
          queue.empty? || queue.first.base_lo > prev_base_hi + 1
        end

        def determine_differnce(diff_diffs_queue, init_side, final_side)
          base_lo = diff_diffs_queue.get(init_side).first.base_lo
          base_hi = diff_diffs_queue.get(final_side).last.base_hi
#          puts "Beta base_lo #{base_lo} base_hi #{base_hi}"
          left_lo,  left_hi    = diffable_endpoints(diff_diffs_queue.get(:left), base_lo, base_hi)
          right_lo, right_hi   = diffable_endpoints(diff_diffs_queue.get(:right), base_lo, base_hi)

          #the endpoints are offset one, neet to account for that in getting subsets
          left_subset = @left[left_lo-1 .. left_hi]
          right_subset = @right[right_lo-1 .. right_hi]
          change_type = decide_action(diff_diffs_queue, left_subset, right_subset)
          [change_type, left_lo, left_hi, right_lo, right_hi, base_lo, base_hi]
        end

        def diffable_endpoints(command, base_lo, base_hi)
          if command.any?
            lo = command.first.side_lo - command.first.base_lo +  base_lo
            hi = command.last.side_hi  - command.last.base_hi  + base_hi
            [lo, hi]
          else
            [base_lo,  base_hi]
          end
        end

        def decide_action(diff_diffs_queue, left_subset, right_subset)
          #adjust because the ranges are 1 indexed

          if diff_diffs_queue.empty?(:left)
            :choose_right
          elsif diff_diffs_queue.empty?(:right)
            :choose_left
          else
            if left_subset != right_subset
              :possible_conflict
            else
              :no_conflict_found
            end
          end
        end
    end

    class DiffDoubleQueue
      attr_reader :current_side
      def initialize(left=[], right=[])
        @diffs = { left: left, right: right }
      end

      def dequeue(side=current_side)
        @diffs[side].shift
      end

      def peek(side=current_side)
        @diffs[side]
      end

      def finished?
        empty?(:left) && empty?(:right)
      end

      def enqueue(side=current_side, val)
        @diffs[side] << val
      end

      def get(side=current_side)
        @diffs[side]
      end

      def empty?(side=current_side)
        @diffs[side].empty?
      end

      def switch_sides(side=current_side)
        @current_side = side == :left ? :right : :left
      end

      def choose_side
        if empty? :left
          @current_side = :right
        elsif empty? :right
          @current_side = :left
        else
          #choose the lowest side relative to base
          @current_side = get(:left).first.base_lo <= get(:right).first.base_lo ? :left : :right
        end
      end
    end

  end
end