module Dyph3
  module Equatable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def equate_with(*fields)
        self.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def hash
            self.class.hash ^ #{fields.map { |field| "#{field}.hash"}.join(" ^ ")}
          end
        CODE

        self.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def ==(other)
            self.class == other.class && #{fields.map { |field| "#{field} == other.#{field}"}.join(" && ")}
          end
          alias_method :eql?, :==
        CODE
      end
    end
  end
end