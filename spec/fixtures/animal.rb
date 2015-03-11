module Animal
  def ==(other)
    other.class == self.class &&
    other.type == self.type
  end
end

class Fish
  include Animal
  attr_accessor :type
  def initialize(type)
    @type = type
  end

end

class Bird
  include Animal
  attr_accessor :type
  def initialize(type)
    @type = type
  end
end