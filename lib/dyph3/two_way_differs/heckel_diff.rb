module Dyph3
  module TwoWayDiffers

    class HeckelDiff
      # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

      def self.execute_diff(old_text_array, new_text_array)
        raise ArgumentError, "Argument is not an array." unless old_text_array.is_a?(Array) && new_text_array.is_a?(Array)

        diff_result = diff(old_text_array, new_text_array)

        # convert to typed differ's output (wrapped with change types eg. Add, Delete, Change)
        convert_to_typed_ouput(diff_result, old_text_array, new_text_array)
      end

      # Two-way diff based on the algorithm by P. Heckel.
      # @param [in] left Array of anything implementing hash and equals
      # @param [in] right Array of anything implementing hash and equals
      def self.diff(left, right)
        differ = HeckelDiff.new(left,right)
        differ.perform_diff
      end

      def initialize(left, right)
        @left = left
        @right = right
      end

      def perform_diff
        unique_positions = identify_unique_postions
        unique_positions.sort!{ |a, b| a[0] <=> b[0] }    # sort by the line in which the line was found in a
        left_change_pos, right_change_pos = find_next_change
        init_changes = ChangeData.new(left_change_pos, right_change_pos, [])
        final_changes = unique_positions.reduce(init_changes, &method(:get_differences))
        final_changes.change_ranges
      end

      private

        ChangeData = Struct.new(:left_change_pos, :right_change_pos, :change_ranges)

        def get_differences(change_data, unique_positions)
          left_pos, right_pos = change_data.left_change_pos, change_data.right_change_pos
          left_uniq_pos, right_uniq_pos = unique_positions
          if left_uniq_pos < left_pos || right_uniq_pos < right_pos
            change_data
          else
            left_lo, left_hi, right_lo, right_hi  = find_prev_change(left_pos, right_pos, left_uniq_pos-1, right_uniq_pos-1)
            next_left_pos, next_right_pos         = find_next_change(left_uniq_pos+1, right_uniq_pos+1)

            updated_ranges = append_change_range(change_data.change_ranges, left_lo, left_hi, right_lo, right_hi)
            ChangeData.new(next_left_pos, next_right_pos, updated_ranges)
          end
        end

        def find_next_change(left_start_pos=0, right_start_pos=0)
          l_arr, r_arr = (@left[left_start_pos..-1] || []), (@right[right_start_pos..-1] || [])
          offset = mismatch_offset l_arr, r_arr
          [ left_start_pos + offset, right_start_pos + offset]
        end


        def find_prev_change(left_lo, right_lo, left_hi, right_hi)
          if left_lo > left_hi || right_lo > right_hi
            [left_lo, left_hi, right_lo, right_hi]
          else
            l_arr, r_arr = (@left[left_lo .. left_hi].reverse || []), (@right[right_lo .. right_hi].reverse || [])
            offset = mismatch_offset l_arr, r_arr
            [left_lo, left_hi - offset, right_lo, right_hi - offset]
          end
        end

        def mismatch_offset(l_arr, r_arr)
          _ , index  = l_arr.zip(r_arr).each_with_index.detect { |pair, _| pair[0] != pair[1] }
          index || [l_arr.length, r_arr.length].min
        end

        def identify_unique_postions
          left_uniques =   find_unique(@left)
          right_uniques =  find_unique(@right)
          shared_keys = left_uniques.keys & right_uniques.keys
          uniq_ranges = shared_keys.map { |k| [left_uniques[k], right_uniques[k]] }
          uniq_ranges.unshift([ @left.length, @right.length])
        end 

        def find_unique(array)
          flagged_uniques = array.each_with_index.reduce({}) do |hash, item_index|
            item, pos = item_index
            hash[item] = {pos: pos, unique: hash[item].nil?}
            hash
          end
          flagged_uniques.select { |_, v| v[:unique] }.map { |k, v| [k, v[:pos]] }.to_h
        end

        # given the calculated bounds of the 2 way diff, create the proper change type and add it to the queue.
        def append_change_range(changes_ranges, left_lo, left_hi, right_lo, right_hi)
          if left_lo <= left_hi && right_lo <= right_hi # for this change, the bounds are both 'normal'.  the beginning of the change is before the end.
            changes_ranges << [:change, left_lo + 1, left_hi + 1, right_lo + 1, right_hi + 1]
          elsif left_lo <= left_hi
            changes_ranges << [:delete, left_lo + 1, left_hi + 1, right_lo + 1, right_lo]
          elsif right_lo <= right_hi
            changes_ranges << [:add, left_lo + 1, left_lo, right_lo + 1, right_hi + 1]
          end
          changes_ranges
        end

        def self.convert_to_typed_ouput(heckel_diff, old_text_array, new_text_array)
          chunks = heckel_diff.map { |block| TwoWayChunk.new(block) }

          old_index = 0
          old_text = []
          new_index = 0
          new_text = []
          chunks.each do |chunk|
            old_iteration = 0
            while old_index + old_iteration < chunk.left_lo - 1     # chunk indexes are from 1
              old_text << TextNode.new(text: old_text_array[old_index + old_iteration], row: new_index + old_iteration)
              old_iteration += 1
            end

            new_iteration = 0
            while new_index + new_iteration < chunk.right_lo - 1     # chunk indexes are from 1
              new_text << TextNode.new(text: new_text_array[new_index + new_iteration], row: old_index + new_iteration)
              new_iteration += 1
            end

            old_index += old_iteration
            new_index += new_iteration

            while old_index <= chunk.left_hi - 1     # chunk indexes are from 1
              old_text << old_text_array[old_index]
              old_index += 1
            end

            while new_index <= chunk.right_hi - 1     # chunk indexes are from 1
              new_text << new_text_array[new_index]
              new_index += 1
            end
          end

          iteration = 0
          while old_index + iteration < old_text_array.length
            old_text << TextNode.new(text: old_text_array[old_index + iteration], row: new_index + iteration)
            iteration += 1
          end

          iteration = 0
          while new_index + iteration < new_text_array.length
            new_text << TextNode.new(text: new_text_array[new_index + iteration], row: old_index + iteration)
            iteration += 1
          end

          { old_text: old_text, new_text: new_text}
        end
    end

    class TextNode
      attr_accessor :text, :row

      def initialize(text:, row:)
        @text = text
        @row  = row
      end
    end

    class TwoWayChunk
      attr_reader :action, :left_lo, :left_hi, :right_lo, :right_hi
      def initialize(raw_chunk)
        @action   = raw_chunk[0]
        @left_lo  = raw_chunk[1]
        @left_hi  = raw_chunk[2]
        @right_lo = raw_chunk[3]
        @right_hi = raw_chunk[4]
      end
    end

  end
end