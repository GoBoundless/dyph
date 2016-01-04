module Dyph3
  class Outcome::Resolved < Outcome
    attr_reader :result
    def initialize(result)
      @result = result
      @combiner = ->(x, y) { x + y }
    end

    def set_combiner(lambda)
      @combiner = lambda
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
       @result = @combiner[@result, other.result]
       self
    end

    def apply(fun)
       Outcome::Resolved.new(fun[result])
    end
  end
end