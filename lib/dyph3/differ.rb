module Dyph3
  class Differ
    #   The differ works on arrays of objects which implement hash and eq.
    #   Spit, Join, and Conflict processors can also be defined in the objects
    #   @param left [Object]
    #   @param base [Object]
    #   @param right [Object]
    #   @params split_function [Proc] Lambda for splitting the objects into Array default is identity
    #   @params join_function [Proc] Lambda for joining the diffed
    #   @params conflict_function [Proc] Lambda for handling conflicts. Take a Dyph3::MergeResult as argument
    #   @params diff2 [Diff3::TwoWayDiffers] Which two way diff class to use
    #   @params diff3 [Diff3] Which diff3 class to use
    #   @params use_overrides [Boolean] you can implement the split, join and conflict functions on a lambda in your object, or ignore it up to you really
    #   @return [Dyph3::MergeResults] The join function is called on each of the results
    def self.merge(left, base, right, split_function: identity, join_function: identity, conflict_function: identity,
      diff2: default_diff2,
      diff3: default_diff3,
      use_overrides: true)

      if use_overrides
        split_function, join_function, conflict_function = check_for_class_overrides(
          base.class,
          split_function,
          join_function,
          conflict_function
        )
      end

      left, base, right = [left, base, right].map { |t| split_function.call(t) }
      merge_result = Dyph3::Support::Merger.merge(left, base, right, diff2: diff2, diff3: diff3 )
      collated_merge_results = Dyph3::Support::Collater.collate_merge(merge_result, join_function, conflict_function)

      if collated_merge_results.success?
        Dyph3::Support::SanityCheck.ensure_no_lost_data(left, base, right, collated_merge_results.results)
      end
      collated_merge_results
    end

    # If you want to execute a two way diff
    # @params leff [Array]
    # @params right [Array]
    # @params diff2 [Diff3::TwoWayDiffers] Which two way diff class to use
    # @return [Array] array of Dyph3::Action
    def self.merge_two_way_diff(left, right, diff2: default_diff2)
      diff_results = diff2.execute_diff(left, right)
      raw_merge = Dyph3::TwoWayDiffers::OutputConverter.merge_results(diff_results[:old_text], diff_results[:new_text],)
      Dyph3::TwoWayDiffers::OutputConverter.objectify(raw_merge)
    end

    # @return helper proc for keeping new lines on string
    def self.split_on_new_line
      -> (some_string) { some_string.split(/(\n)/).each_slice(2).map { |x| x.join } }
    end

    # @return helper proc for joining an array
    def self.standard_join
      -> (array) { array.join }
    end

    # @return helper proc for identity
    def self.identity
      -> (x) { x }
    end

    # @return default diff2 class
    def self.default_diff2
      Dyph3::TwoWayDiffers::OriginalHeckelDiff
    end
    # @return default diff3 class
    def self.default_diff3
      Dyph3::Support::Diff3
    end

    def self.check_for_class_overrides(klass, split_function, join_function, conflict_function)
      if klass.constants.include?(:DIFF_PREPROCESSOR)
        split_function = klass::DIFF_PREPROCESSOR
      end

      if klass.constants.include?(:DIFF_POSTPROCESSOR)
        join_function  = klass::DIFF_POSTPROCESSOR
      end

      if klass.constants.include?(:DIFF_CONFLICT_PROCESSOR)
        conflict_function = klass::DIFF_CONFLICT_PROCESSOR
      end

      [split_function, join_function, conflict_function]
    end

  end
end