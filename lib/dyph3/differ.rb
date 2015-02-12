module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html
    def self.merge_text(left, base, right)
      valid_arguments = [left, base, right].inject(true){ |memo, arg| memo && arg.is_a?(String) }
      raise ArgumentError, "Argument is not a string." unless valid_arguments

      merge_result = Dyph3::Support::Merger.merge(left.split("\n"), base.split("\n"), right.split("\n"))
      return_value = Dyph3::Support::Collater.collate_merge(left, base, right, merge_result)

      # sanity check: make sure anything new in left or right made it through the merge
      Dyph3::Support::SanityCheck.ensure_no_lost_data(left, base, right, return_value)
      return_value
    end
  end

end