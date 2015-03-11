module Dyph3
  class Base
    attr_reader :value, :old_index, :new_index

    def initialize(value:, old_index:, new_index:)
      @value = value
      @old_index = old_index
      @new_index = new_index
    end

  end
end