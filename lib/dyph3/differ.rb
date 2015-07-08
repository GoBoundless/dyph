module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

    def self.merge_two_way_diff(left_array, right_array, current_differ: Dyph3::TwoWayDiffers::HeckelDiff)
      diff_results = current_differ.execute_diff(left_array, right_array)
      raw_merge = Dyph3::TwoWayDiffers::OutputConverter.merge_results(diff_results[:old_text], diff_results[:new_text])
      Dyph3::TwoWayDiffers::OutputConverter.objectify(raw_merge)
    end

    def self.merge_text(left, base, right, current_differ: Dyph3::TwoWayDiffers::HeckelDiff, split_function: split_on_new_line, join_function: standard_join, conflict_function: nil)
      split_function = base.class::DIFF_PREPROCESSOR   if base.class.constants.include?(:DIFF_PREPROCESSOR)
      join_function  = base.class::DIFF_POSTPROCESSOR  if base.class.constants.include?(:DIFF_POSTPROCESSOR)

      conflict_function = base.class::DIFF_CONFLICT_PROCESSOR if base.class.constants.include?(:DIFF_CONFLICT_PROCESSOR)

      left, base, right = [left, base, right].map { |t| split_function.call(t) }

      # short circuit diffing if left or right == base
      if left == base
        result = join_function.call(right)
        return [result, false, [{ type: :non_conflict, text: result }]]
      elsif right == base
        result = join_function.call(left)
        return [result, false, [{ type: :non_conflict, text: result }]]
      end

      merge_result = Dyph3::Support::Merger.merge(left, base, right, current_differ: current_differ)
      return_value = Dyph3::Support::Collater.collate_merge(left, base, right, merge_result)

      # sanity check: make sure anything new in left or right made it through the merge
      if has_conflict(return_value) && conflict_function
        conflict_function[return_value]
      else
        Dyph3::Support::SanityCheck.ensure_no_lost_data(left, base, right, return_value)
        join_results(return_value, join_function: join_function)
      end
    end

    def self.has_conflict(return_value)
      return_value[1] #conflict indicator index
    end

    def self.split_on_new_line
      -> (some_string) { some_string.split(/(\n)/).each_slice(2).map { |x| x.join } }
    end

    def self.standard_join
      -> (array) { array.join }
    end

    def self.join_results(old_results, join_function:)
      new_results = []
      new_results[0] = join_function.call old_results[0]
      new_results[1] = old_results[1]

      new_results[2] = old_results[2].map do |hash|
        return_hash = {}
        hash.keys.map do |key|
          if key == :type
            return_hash[key] = hash[key]
          else
            return_hash[key] = join_function.call(hash[key])
          end
        end
        return_hash
      end
      new_results
    end
  end

end