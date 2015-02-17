module Dyph3
  module TwoWayDiffers
    module ResigDiff
      extend self

      def diff(old_text_array, new_text_array)
        results = execute_diff(old_text_array, new_text_array)
        converter = Dyph3::TwoWayDiffers::OutputConverter
        #merge_results = converter.merge_results(results[:old_text], results[:new_text])
        converter.convert_to_dyph3_output(results[:old_text], results[:new_text])
      end

      def execute_diff(old_text_array, new_text_array)
        raise ArgumentError, "Argument is not an array." unless  old_text_array.is_a?(Array) && new_text_array.is_a?(Array)

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

        { old_text: old_text, new_text: new_text}
      end

      private
        def create_diffing_hash(values)
          hash = {}
          values.each_with_index do |value, i|
            hash[value] ||= { rows: [] }
            hash[value][:rows] << i
          end
          hash
        end

        def find_single_matches(new_hash, old_hash, old_text, new_text)
          new_hash.keys.each do |i|
            if (!old_hash[i].nil? && new_hash[i][:rows].length == 1 && old_hash[i][:rows].length == 1)
              new_hash_row = new_hash[i][:rows][0]
              old_hash_row = old_hash[i][:rows][0]
              new_text[new_hash_row]  = TextNode.new(text: new_text[new_hash_row], row: old_hash_row)
              old_text[old_hash_row ]  = TextNode.new(text: old_text[old_hash_row], row: new_hash_row)
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
          optional(new_text[i]).text.value &&                           # current value is marked as uniq
          boundry_check(new_text, old_text, i, caller: caller) &&       # not off the end of the array
          !(optional(new_text[i + offset]).text.value) &&               # value + offset is not marked as unique
          !(optional(old_text[new_text[i].row + offset]).text.value) && # the old text not marked unique
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
