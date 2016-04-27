module Dyph

  # Perform a two-way diff of the given arrays twice, the second time with left and right reversed, and return the smaller result.
  # @param left [Object]
  # @param base [Object]
  # @return [MergeResult]
  def self.min_diff(left, right)
    a = Differ.two_way_diff(left, right)
    b = Differ.two_way_diff(right, left)
    if a.size <= b.size
      a
    else
      sort_actions(invert_actions(b))
    end
  end

  # Invert the meanings of deleted and added chunks.
  # @param actions [object]
  # @return actions [object]
  def self.invert_actions(actions)
    actions.map do |action|
      case action
      when Action::Add     then Action::Delete.new(value: action.value, old_index: action.old_index, new_index: action.new_index)
      when Action::Delete  then Action::Add.new(value:    action.value, old_index: action.old_index, new_index: action.new_index)
      else action
      end
    end
  end

  # Reorder a diff result so that deletes are always before adds.
  # @param actions [object]
  # @return actions [object]
  def self.sort_actions(actions)
    actions = actions.reduce([]) do |result, action|
      case action
      when Action::Delete, Action::Add
        ChangeGroup.begin(result)
        result.last.add action
      when Action::NoChange
        ChangeGroup.end(result)
        result << action
      end
      result
    end
    ChangeGroup.end(actions)
    return actions
  end

  class ChangeGroup

    def initialize
      @adds = []
      @deletes = []
    end

    def add(change)
      case change
      when Action::Delete then @deletes << change
      when Action::Add    then @adds    << change
      end
    end

    def values
      [*@deletes, *@adds]
    end

    def self.begin(action)
      action << new unless action.last.is_a? self
    end

    def self.end(action)
      action.concat(action.pop.values) if action.last.is_a? self
    end
  end

end
