module Dyph3
  module TwoWayDiffers
    module ResigDiff
      extend self

      def diff(old_text_array, new_text_array)
        results = execute_diff(old_text_array, new_text_array)
        converter = Dyph3::TwoWayDiffers::OutputConverter
        converter.convert_to_dyph3_output(results[:old_text], results[:new_text])
      end

      def execute_diff(old_text_array, new_text_array)
        raise ArgumentError, "Argument is not an array." unless old_text_array.is_a?(Array) && new_text_array.is_a?(Array)

        old_text, new_text = [old_text_array, new_text_array].map(&:dup)

        old_hash = create_diffing_hash(old_text)

        new_hash = create_diffing_hash(new_text)
        find_single_matches(new_hash, old_hash, old_text, new_text)

        if !new_text.first.nil? && new_text[0] == old_text[0]
          new_text[0] = TextNode.new(text: new_text[0], row: 0)
          old_text[0] = TextNode.new(text: old_text[0], row: 0)
        end

        find_multi_matches(new_text, old_text, caller: :ascending)

        if !old_text.last.nil? && new_text.last == old_text.last
          new_text[new_text.length-1] = TextNode.new(text: new_text.last, row: old_text.length-1)
          old_text[old_text.length-1] = TextNode.new(text: old_text.last, row: new_text.length-1)
        end

        find_multi_matches(new_text, old_text, caller: :descending)

        convert_moves_to_additions(old_text, new_text)

        { old_text: old_text, new_text: new_text}
      end

      private
        # convert_moves_to_additions converts a "move" change into an addition (and a deletion).
        # This is necessary for the 3 way differ, otherwise information is lost when elements
        # move around.
        def convert_moves_to_additions(old_text, new_text)
          new_text.each_with_index do |value, index|
            convert_moves_to_additions_for_array(new_text, index, old_text)
          end
          old_text.each_with_index do |value, index|
            convert_moves_to_additions_for_array(old_text, index, new_text)
          end
        end

        def convert_moves_to_additions_for_array(array, index, matching_array)
          return if index >= array.length || index < 0
          value = array[index]

          indexes_needing_conversion = []
          value = array[index]

          if index > 1
            previous_value = array[index - 1]
            previous_previous_value = array[index - 2]
            if previous_value.is_a?(Dyph3::TwoWayDiffers::TextNode) \
              && previous_previous_value.is_a?(Dyph3::TwoWayDiffers::TextNode) \
              && previous_value.row < previous_previous_value.row
              indexes_needing_conversion << index - 1
            end
          end
          if index < array.length - 1
            next_value = array[index + 1]
            next_next_value = array[index + 2]
            if next_value.is_a?(Dyph3::TwoWayDiffers::TextNode) \
              && next_next_value.is_a?(Dyph3::TwoWayDiffers::TextNode) \
              && next_value.row > next_next_value.row
              indexes_needing_conversion << index + 1
            end
          end

          indexes_needing_conversion.each do |convert_index|
            convert_value = array[convert_index]
            array[convert_index] = convert_value.text
            matching_array_index = convert_value.row
            matching_array[matching_array_index] = convert_value.text

            # make sure we didn't "break" any new nodes by removing this anchor
            convert_moves_to_additions_for_array(array, convert_index + 1, matching_array)
            convert_moves_to_additions_for_array(array, convert_index - 1, matching_array)
            convert_moves_to_additions_for_array(matching_array, matching_array_index + 1, array)
            convert_moves_to_additions_for_array(matching_array, matching_array_index - 1, array)
          end
        end

        def create_diffing_hash(values)
          hash = {}
          values.each_with_index do |value, index|
            hash[value] ||= { rows: [] }
            hash[value][:rows] << index
          end
          hash
        end

        def find_single_matches(new_hash, old_hash, old_text, new_text)
          new_hash.keys.each do |i|
            if (!old_hash[i].nil? && new_hash[i][:rows].length == 1 && old_hash[i][:rows].length == 1)
              new_hash_row = new_hash[i][:rows][0]
              old_hash_row = old_hash[i][:rows][0]
              new_text[new_hash_row]  = TextNode.new(text: new_text[new_hash_row], row: old_hash_row)
              old_text[old_hash_row]  = TextNode.new(text: old_text[old_hash_row], row: new_hash_row)
            end
          end
        end

        def find_multi_matches(new_text, old_text, caller:)
          offset = get_offset(caller: caller)
          set_range(new_text, old_text, caller: caller).each do |i|
            if is_unchanged?(new_text, old_text, i, offset: offset, caller: caller)
              new_text_row = new_text[i].row + offset
              new_text[i + offset]   = TextNode.new(text: new_text[i + offset], row: new_text_row)
              old_text[new_text_row] = TextNode.new(text: old_text[new_text_row], row: i + offset)
            end
          end
        end

        def get_offset(caller:)
          if caller == :ascending
            1
          elsif caller == :descending
            -1
          else
            raise "bad caller"
          end
        end

        def set_range(new_text, old_text, caller:)
          if caller == :ascending
            (0 ... new_text.length)
          elsif caller == :descending
            (new_text.length - 1).downto(0)
          else
            raise "bad caller"
          end
        end


       def is_unchanged?(new_text, old_text, i, offset:, caller:)
          new_text[i].is_a?(TextNode) &&                                # current value is marked as uniq
          boundry_check(new_text, old_text, i, caller: caller) &&       # not off the end of the array
          !new_text[i + offset].is_a?(TextNode) &&                      # value + offset is not marked as unique
          !old_text[new_text[i].row + offset].is_a?(TextNode) &&        # the old text not marked unique
          new_text[i + offset] == old_text[new_text[i].row + offset ]   # and the value in question matches
        end

        def boundry_check(new_text, old_text, i, caller:)
          if caller == :ascending
            new_text[i].row + 1 < old_text.length
          elsif caller == :descending
            new_text[i].row > 0
          else
            raise "bad caller"
          end
        end

        def optional(value)
          Monads::Optional.new(value)
        end
      end

    class TextNode
      attr_accessor :text, :row

      def initialize(text:, row:)
        @text = text
        @row  = row
      end
    end
  end
end
