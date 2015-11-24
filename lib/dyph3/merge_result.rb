module Dyph3
  class MergeResult
    attr_reader :results
    def initialize(results, join_function, conflict_handler=nil)
      @results = results
      @join_function = join_function
      @conflict_handler = conflict_handler
    end

    def success?
      self.class == Dyph3::MergeResult::Success
    end

    def conflict?
      self.class == Dyph3::MergeResult::Conflict
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
  end


end