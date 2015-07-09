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
            convert_moves_to_additions_at_index(new_text, index, old_text)
          end
          old_text.each_with_index do |value, index|
            convert_moves_to_additions_at_index(old_text, index, new_text)
          end
        end

        def convert_moves_to_additions_at_index(array, index, matching_array)
          value = array[index]

          # we're not a TextNode so this is already an addition (or deletion)
          return if !value.is_a?(Dyph3::TwoWayDiffers::TextNode)

          # there's no next element so we can't be a broken move
          return if index >= array.length - 1

          next_value = array[index + 1]

          # the next element isn't a TextNode so we can't be broken
          return if !next_value.is_a?(Dyph3::TwoWayDiffers::TextNode)

          if value.row > next_value.row
            # we were moved behind the next value, convert this move to an addition and deletion
            array[index] = value.text
            matching_array_index = value.row
            matching_array[matching_array_index] = value.text
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
