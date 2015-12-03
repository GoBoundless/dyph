module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

    def self.merge_two_way_diff(left_array, right_array, current_differ: Dyph3::TwoWayDiffers::HeckelDiff)
      diff_results = current_differ.execute_diff(left_array, right_array)
      raw_merge = Dyph3::TwoWayDiffers::OutputConverter.merge_results(diff_results[:old_text], diff_results[:new_text],)
      Dyph3::TwoWayDiffers::OutputConverter.objectify(raw_merge)
    end

    def self.merge(left, base, right, current_differ: Dyph3::TwoWayDiffers::OriginalHeckelDiff, split_function: ->(x) { x } , join_function: ->(x) { x }, conflict_function: nil)
      self.merge_text(left, base, right, current_differ: current_differ, split_function: split_function, join_function: join_function, conflict_function: conflict_function)
    end

    def self.merge_text(left, base, right, current_differ: Dyph3::TwoWayDiffers::HeckelDiff, split_function: split_on_new_line, join_function: standard_join, conflict_function: nil)
      split_function = base.class::DIFF_PREPROCESSOR   if base.class.constants.include?(:DIFF_PREPROCESSOR)
      join_function  = base.class::DIFF_POSTPROCESSOR  if base.class.constants.include?(:DIFF_POSTPROCESSOR)

      conflict_function = base.class::DIFF_CONFLICT_PROCESSOR if base.class.constants.include?(:DIFF_CONFLICT_PROCESSOR)

      left, base, right = [left, base, right].map { |t| split_function.call(t) }

      merge_result = Dyph3::Support::Merger.merge(left, base, right, current_differ: current_differ)
      collated_merge_results = Dyph3::Support::Collater.collate_merge(merge_result, join_function, conflict_function)
      if collated_merge_results.success?
        Dyph3::Support::SanityCheck.ensure_no_lost_data(left, base, right, collated_merge_results.results)
      end

      collated_merge_results
    end

    def self.split_on_new_line
      -> (some_string) { some_string.split(/(\n)/).each_slice(2).map { |x| x.join } }
    end

    def self.standard_join
      -> (array) { array.join }
    end
  end
end