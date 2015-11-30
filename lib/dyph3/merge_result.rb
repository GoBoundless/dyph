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

    def typed_results
      #results but with the joined function applied to the text fields
      results.map{ |result| result.apply(@join_function)}
    end

    def joined_results
      if conflict?
        if @conflict_handler
          @conflict_handler[results]
        else
          typed_results
        end
      else
        @join_function[results.first.result]
      end
    end
  end
end