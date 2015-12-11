module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

    def self.default_differ
      Dyph3::TwoWayDiffers::OriginalHeckelDiff
    end

    def self.default_diff3
      Dyph3::Support::Diff3Beta
    end

    def self.merge_two_way_diff(left_array, right_array, current_differ: default_differ)
      diff_results = current_differ.execute_diff(left_array, right_array)
      raw_merge = Dyph3::TwoWayDiffers::OutputConverter.merge_results(diff_results[:old_text], diff_results[:new_text],)
      Dyph3::TwoWayDiffers::OutputConverter.objectify(raw_merge)
    end

    def self.merge(left, base, right, split_function: identity, join_function: identity,
      conflict_function: nil,
      current_differ: default_differ,
      diff3:          default_diff3 )
      if base.class.constants.include?(:DIFF_PREPROCESSOR)
        split_function = base.class::DIFF_PREPROCESSOR
      end
      if base.class.constants.include?(:DIFF_POSTPROCESSOR)
        join_function  = base.class::DIFF_POSTPROCESSOR
      end

      if base.class.constants.include?(:DIFF_CONFLICT_PROCESSOR)
        conflict_function = base.class::DIFF_CONFLICT_PROCESSOR
      end

      left, base, right = [left, base, right].map { |t| split_function.call(t) }
      merge_result = Dyph3::Support::Merger.merge(left, base, right, current_differ: current_differ, diff3: diff3 )
      collated_merge_results = Dyph3::Support::Collater.collate_merge(merge_result, join_function, conflict_function)

      if collated_merge_results.success?
        Dyph3::Support::SanityCheck.ensure_no_lost_data(left, base, right, collated_merge_results.results)
      end

      collated_merge_results
    end

    def self.identity
      -> (x) { x }
    end

    def self.split_on_new_line
      -> (some_string) { some_string.split(/(\n)/).each_slice(2).map { |x| x.join } }
    end

    def self.standard_join
      -> (array) { array.join }
    end
  end
end