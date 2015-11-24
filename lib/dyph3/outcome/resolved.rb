module Dyph3
  class Outcome::Resolved < Outcome
    attr_reader :result
    def initialize(result)
      @result = result
    end

    def ==(other)
      self.class == other.class &&
      self.result == other.result
    end

    alias_method :eql?, :==

    def hash
      self.result.hash
    end

    def combine(other)
       @result += other.result
    end

    def apply(fun)
       Outcome::Resolved.new(fun[result])
    end
  end
end