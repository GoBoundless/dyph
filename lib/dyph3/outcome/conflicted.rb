module Dyph3
  class Outcome::Conflicted < Outcome
    attr_reader :left, :right, :base
    def initialize(left:, base:, right:)
      @left   = left
      @base   = base
      @right  = right
    end

    def ==(other)
      self.class == other.class &&
      self.left == other.left &&
      self.base == other.base &&
      self.right == other.right
    end

    alias_method :eql?, :==

    def hash
      self.left.hash ^ self.base.hash ^ self.right.hash
    end

    def apply(fun)
       self.class.new(left: fun[@left], base: fun[@base], right: fun[@right])
    end
  end
end