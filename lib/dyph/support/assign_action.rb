module Dyph
  module Support
    module AssignAction
      extend self
      def self.get_action(lo_a:, lo_b:, hi_a:, hi_b:)
        if lo_a <= hi_a && lo_b <= hi_b # for this change, the bounds are both 'normal'.  the beginning of the change is before the end.
          [:change, lo_a + 1, hi_a + 1, lo_b + 1, hi_b + 1]
        elsif lo_a <= hi_a
          [:delete, lo_a + 1, hi_a + 1, lo_b + 1, lo_b]
        elsif lo_b <= hi_b
          [:add, lo_a + 1, lo_a, lo_b + 1, hi_b + 1]
        else
          nil
        end
      end
    end
  end
end
