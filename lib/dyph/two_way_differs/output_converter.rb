module Dyph
  module TwoWayDiffers
    # rubocop:disable Metrics/ModuleLength
    module OutputConverter
      extend self

      def convert_to_dyph_output(old_text, new_text)
        actions =  merge_and_partition(old_text, new_text)
        selected_actions = extract_add_deletes_changes(actions)
        correct_offsets(selected_actions)
      end

      def objectify(merge_results)
        merge_results.map do |result|
          action = result[:action]
          line   = result[:line]
          old_index = result[:old_index]
          new_index = result[:new_index]

          case action
          when :add
            Dyph::Action::Add.new(value: line, old_index: old_index, new_index: new_index)
          when :delete
            Dyph::Action::Delete.new(value: line, old_index: old_index, new_index: new_index)
          when :no_change
            Dyph::Action::NoChange.new(value: line.text, old_index: old_index, new_index: new_index)
          else
            raise "unhandled action"
          end
        end
      end

      def merge_results(old_text, new_text)
        merged_text = []

        if (new_text.empty?)
          no_new_text(old_text, merged_text)
        else
          prepend_old_text(old_text, merged_text)
          gather_up_actions(old_text, new_text, merged_text)
        end
        merged_text
      end

      private
        def merge_and_partition(old_text, new_text)
          merged_text = merge_results(old_text, new_text)
          merge_output_lines = merged_text.map { |x| to_output_format x }
          partition_into_actions(merge_output_lines)
        end

        def extract_add_deletes_changes(actions)
          collapsed_actions = actions.map { |action| collapse_action(action) }
          paired_results = pair_up_add_deletes collapsed_actions
          paired_results.reject { |res| res[:action] == :no_change}
        end

        def correct_offsets(selected_actions)
          fix_offsets = set_offset(selected_actions)
          fix_offsets.map { |r| Dyph::Support::AssignAction.get_action(
            lo_a: r[:old_lo]-1 ,
            lo_b: r[:new_lo]-1,
            hi_a: r[:old_hi]-1,
            hi_b: r[:new_hi]-1
          )}
        end

        def gather_up_actions(old_text, new_text, merged_text)
          prev_no_change_old = - 1
          new_text.map.with_index.each do |line, i|
            if !line.is_a?(TextNode)
              merged_text << {action: :add, line: line, old_index: prev_no_change_old + 1, new_index: i+1}
            else
              prev_no_change_old = line.row
              change_or_delete(old_text, line, prev_no_change_old, merged_text, i)
            end
          end
        end

        def change_or_delete(old_text, line, prev_no_change_old, merged_text, index)
          merged_text << {action: :no_change, line: line, old_index: line.row, new_index: index}

          ((prev_no_change_old+1) ... old_text.length).each do |n|
            break if old_text[n].is_a?(TextNode)
            merged_text << {action: :delete, line: old_text[n], old_index: n+1, new_index: index+1}
          end
        end

        def prepend_old_text(old_text, merged_text)
          if !old_text.first.is_a?(TextNode)
            old_text.map.with_index.each do |line, i|
              break if line.is_a?(TextNode)
              merged_text << {action: :delete, line: line, old_index:i+1, new_index: i}
            end
          end
        end

        def no_new_text(old_text, merged_text)
          old_text.map.with_index do |line, i|
            merged_text << { action: :delete, line: line, old_index: i+1, new_index: i}
          end
        end

        def set_offset(results)
          results.map do |result_row|
            if result_row[:action] == :add
              result_row[:old_lo] += 1
              result_row
            elsif result_row[:action] == :delete
              result_row[:new_lo] += 1
              result_row
            else
              result_row
            end
          end
        end

        def to_output_format(result_row)
          {
            action: result_row[:action],
            old_lo: result_row[:old_index],
            old_hi: result_row[:old_index],
            new_lo: result_row[:new_index],
            new_hi: result_row[:new_index]
          }
        end

        def collapse_action(actions)
          actions.inject({}) do | hash, action |
            hash[:action] ||= action[:action]
            hash[:old_lo] ||= action[:old_lo]
            hash[:old_hi] =   action[:old_hi]
            hash[:new_lo] ||= action[:new_lo]
            hash[:new_hi] =   action[:new_hi]
            hash
          end
        end

        def is_a_pair?(actions, i)
          action_one =  actions[i-1][:action] if actions[i-1]
          action_two =  actions[i][:action]   if actions[i]
          Set.new([action_one, action_two]) == Set.new([:add, :delete])
        end

        def pair_up_add_deletes(actions)
          results = []
          found_change = false
          (1 .. actions.length).each do |i|
            if is_a_pair?(actions, i)
              results << {
                action: :change,
                old_lo: actions[i-1][:old_lo],
                old_hi: actions[i-1][:old_hi],
                new_lo: actions[i][:new_lo],
                new_hi: actions[i][:new_hi]
              }
              found_change = true
            elsif found_change
              found_change = false
            else
              results << actions[i-1]
            end
          end
          results
        end

        def partition_into_actions(array)
          array.inject([]) do |acc, x|
            if acc.length == 0 || acc.last.last[:action] != x[:action]
              acc << [x]
            else
              acc.last << x
            end
            acc
          end
        end
    end
  end
end
