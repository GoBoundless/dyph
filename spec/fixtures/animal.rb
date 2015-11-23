module Animal
  def ==(other)
    other.class == self.class &&
    other.type == self.type
  end

  alias_method :eql?, :==

  def hash
    type.hash
  end
end

class Fish
  include Animal
  DIFF_PREPROCESSOR = -> (animal) { [animal.type] }
  DIFF_POSTPROCESSOR = -> (animal_array) { Fish.new(animal_array.first) }
  DIFF_CONFLICT_PROCESSOR = ->(differ_output) do
    differ_output.first[:conflict_custom] = [:tuna]
    differ_output
  end
  attr_accessor :type
  def initialize(type)
    @type = type
  end

  def text
    "Blub"
  end

end

class Bird
  include Animal

  attr_accessor :type
  def initialize(type)
    @type = type
  end

  def text
    "Tweet"
  end

end