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
      results.map do |hash|
        return_hash = {}
        hash.keys.map do |key|
          if key == :type
            return_hash[key] = hash[key]
          else
            return_hash[key] = @join_function.call(hash[key])
          end
        end
        return_hash
      end
    end

    def joined_results
      if conflict?
        if @conflict_handler
          @conflict_handler[results]
        else
          typed_results
        end
      else
        @join_function[results[0][:text]]
      end
    end
  end
end