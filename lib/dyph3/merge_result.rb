module Dyph3
  class MergeResult

    # @param results [Array]  diff3 output
    # @oaram join_fuction [Proc] how to join the results together
    # @param conflict [Boolean] sets the conflict's state
    # @param conflict handler [Proc] what to do with the conflicted results
    def initialize(results, join_function, conflict: false, conflict_handler: nil)
      @results = results
      @join_function = join_function
      @conflict_handler = conflict_handler
      @conflict = conflict
    end

    # @return [Array] of outcomes (Outcome::Conflicted  or Outcome::Resolved)
    def results
      @results
    end

    #@return [Boolean] success state
    def success?
      !@conflict
    end

    #@return [Boolean] conflict state
    def conflict?
      @conflict
    end

    # Applies the join function or conflict handler to diff3 results array
    # @returns the results with the methods provided by user or defaults applied
    def joined_results
      if conflict?
        if @conflict_handler
          @conflict_handler[results]
        else
          results
        end
      else
        first, rest = results.first, results[1..-1]
        rest.reduce(first) { |rs, r| rs.combine(r) }.apply(@join_function).result
      end
    end
  end
end