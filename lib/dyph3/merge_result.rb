module Dyph3
  class MergeResult
    attr_reader :value
    def initialize(value, join_function, conflict_handler=nil)
      @value = value
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
      value.map do |hash|
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