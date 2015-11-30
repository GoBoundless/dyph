module Dyph3
  class MergeResult
    attr_reader :results
    def initialize(results, join_function, conflict: false, conflict_handler: nil)
      @results = results
      @join_function = join_function
      @conflict_handler = conflict_handler
      @conflict = conflict
    end

    def success?
      !@conflict
    end

    def conflict?
      @conflict
    end

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