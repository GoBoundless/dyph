module Dyph3
  module Support
    module SanityCheck
      extend self

      def ensure_no_lost_data(left, base, right, return_value)
        final_result = return_value[2]

        result_word_map = {}

        final_result.each do |result_block|
          block_text = case result_block[:type]
            when :non_conflict then result_block[:text]
            when :conflict then "#{result_block[:ours]} #{result_block[:theirs]}"
            else raise "Unknown block type, #{result_block[:type]}"
          end
          count_words(block_text, result_word_map)
        end

        left_word_map, base_word_map, right_word_map = [left, base, right].map { |str| count_words(str) }

        # new words are words that are in left or right, but not in base
        new_left_words = subtract_words(left_word_map, base_word_map)
        new_right_words = subtract_words(right_word_map, base_word_map)

        # now make sure all new words are somewhere in the result
        missing_new_left_words = subtract_words(new_left_words, result_word_map)
        missing_new_right_words = subtract_words(new_right_words, result_word_map)

        if missing_new_left_words.any? || missing_new_right_words.any?
          raise BadMergeException.new(return_value)
        end
      end

      private
        def count_words(str, hash={})
          str.split(/\s+/).reduce(hash) do |map, word|
            map[word] ||= 0
            map[word] += 1
            map
          end
        end

        def subtract_words(left_map, right_map)
          remaining_words = {}
          
          left_map.each do |word, count|
            count_in_right = right_map[word] || 0
            
            new_count = count - count_in_right
            remaining_words[word] = new_count if new_count > 0
          end
          
          remaining_words
        end
    end

    class BadMergeException < StandardError
      attr_accessor :merge_result

      def initialize(merge_result)
        @merge_result = merge_result
      end

      def inspect
        "<#{self.class}: #{merge_result}>"
      end

      def to_s
        inspect
      end
    end
  end
end