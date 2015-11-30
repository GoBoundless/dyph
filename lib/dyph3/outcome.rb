module Dyph3
  class Outcome
    def resolved?
      self.class == Outcome::Resolved
    end

    def conflicted?
      self.class == Outcome::Conflicted
    end

  end
end