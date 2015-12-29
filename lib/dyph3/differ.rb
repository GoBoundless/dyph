module Dyph3
  class Differ
    # Perform a three way diff, which attempts to merge left and right relative to a common base
    # @param left [Object]
    # @param base [Object]
    # @param right [Object]
    # @param options [Hash] custom split, join, conflict functions, can also override the diff2 and diff3 algorithm. (see default_merge_options)
    # @return [MergeResult]
    def self.merge(left, base, right, options = {})
      options = default_merge_options.merge(options)

      split_function, join_function, conflict_function = set_processors(base, options)
      split_left, split_base, split_right = [left, base, right].map { |t| split_function.call(t) }
      merge_result = Dyph3::Support::Merger.merge(split_left, split_base, split_right, diff2: options[:diff2], diff3: options[:diff3] )
      collated_merge_results = Dyph3::Support::Collater.collate_merge(merge_result, join_function, conflict_function)

      if collated_merge_results.success?
        Dyph3::Support::SanityCheck.ensure_no_lost_data(split_left, split_base, split_right, collated_merge_results.results)
      end

      collated_merge_results
    end

    # Perform a two way diff
    # @param left [Array]
    # @param right [Array]
    # @param options [Hash] Pass in an optional diff2 class
    # @return [Array] array of Dyph3::Action
    def self.two_way_diff(left, right, options = {})
      diff2 = options[:diff2] || default_diff2
      diff_results = diff2.execute_diff(left, right)
      raw_merge = Dyph3::TwoWayDiffers::OutputConverter.merge_results(diff_results[:old_text], diff_results[:new_text],)
      Dyph3::TwoWayDiffers::OutputConverter.objectify(raw_merge)
    end

    # @return [Proc] helper proc for keeping newlines on string
    def self.split_on_new_line
      -> (some_string) { some_string.split(/(\n)/).each_slice(2).map { |x| x.join } }
    end

    # @return [Proc] helper proc for joining an array
    def self.standard_join
      -> (array) { array.join }
    end

    # @return [Proc] helper proc for identity
    def self.identity
      -> (x) { x }
    end

    # @return [Hash] the default options for a merge
    def self.default_merge_options
      {
        split_function: identity,
        join_function: identity,
        conflict_function: identity,
        diff2: default_diff2,
        diff3: default_diff3,
        use_class_processors: true
      }
    end

    # @return [TwoWayDiffer]
    def self.default_diff2
      Dyph3::TwoWayDiffers::HeckelDiff
    end

    # @return [ThreeWayDiffer]
    def self.default_diff3
      Dyph3::Support::Diff3
    end

    def self.set_processors(base, options)
      split_function    = options[:split_function]
      join_function     = options[:join_function]
      conflict_function = options[:conflict_function]
      if options[:use_class_processors]
        check_for_class_overrides(base.class, split_function, join_function, conflict_function)
      else
        [split_function, join_function, conflict_function]
      end
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

    private_class_method :check_for_class_overrides, :set_processors
  end
end