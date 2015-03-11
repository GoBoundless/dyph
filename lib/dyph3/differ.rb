module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

    def self.merge_two_way_diff(left_array, right_array, current_differ: Dyph3::TwoWayDiffers::ResigDiff)
      diff_results = current_differ.execute_diff(left_array, right_array)
      raw_merge = Dyph3::TwoWayDiffers::OutputConverter.merge_results(diff_results[:old_text], diff_results[:new_text])
      Dyph3::TwoWayDiffers::OutputConverter.objectify(raw_merge)
    end

    def self.merge_text(left, base, right, current_differ: Dyph3::TwoWayDiffers::HeckelDiff, split_function: split_on_new_line, join_funtion: standard_join)
      left, base, right = [left, base, right].map { |t| split_function.call(t) }
      merge_result = Dyph3::Support::Merger.merge(left, base, right, current_differ: current_differ)
      return_value = Dyph3::Support::Collater.collate_merge(left, base, right, merge_result)

      # sanity check: make sure anything new in left or right made it through the merge
      Dyph3::Support::SanityCheck.ensure_no_lost_data(left, base, right, return_value)
      join_results(return_value, join_function: join_funtion )
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