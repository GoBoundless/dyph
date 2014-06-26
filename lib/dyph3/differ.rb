module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

    DEFAULT_OPTIONS = {
      markers: {
        left: "<<<<<<<",
        base: "|||||||",
        right: "=======",
        close: ">>>>>>>"
      },
      include_base: true
    }

    def self.diff3_text(yourtext, original, theirtext, options={})
      diff3(yourtext.split("\n"), original.split("\n"), theirtext.split("\n"), options)
    end

    def self.merge_text(yourtext, original, theirtext, options={})
      result = merge(yourtext.split("\n"), original.split("\n"), theirtext.split("\n"), options)

      #result[:body] = result[:body].join("\n")

      result
    end



    # Three-way diff based on the GNU diff3.c by R. Smith.
    #   @param [in] yourtext    Array of lines of your text.
    #   @param [in] origtext    Array of lines of original text.
    #   @param [in] theirtext   Array of lines of their text.
    #   @returns Array of tuples containing diff results. The tuples consist of
    #        (cmd, loA, hiA, loB, hiB), where cmd is either one of
    #        '0', '1', '2', or 'A'.
    def self.diff3(yourtext, origtext, theirtext)
      # diff result => [(cmd, loA, hiA, loB, hiB), ..]
      d2 = {
        your: diff(origtext, yourtext), # queue of conflicts with your
        their: diff(origtext, theirtext) # queue of conflicts with their
      }
      result_diff3 = []
      r3 = [nil,  0, 0,  0, 0,  0, 0]
      # continue iterating while there are still conflicts.  goal is to get a set of 3conflicts (cmd, loA, hiA, loB, hiB) 
      while d2[:your].length > 0 || d2[:their].length > 0
        # find a continual range in origtext lo2...hi2
        # changed by yourtext or by theirtext.
        #
        #     d2[:your]            222    222222222
        #  origtext             ..L!!!!!!!!!!!!!!!!!!!!H..
        #     d2[:their]             222222   22  2222222

        # TODO describe what a target is
        i_target = nil
        j_target = nil
        k_target = nil

        r2 = {
          your: [],
          their: []
        }

        #run out of conflicts in :your queue
        if d2[:your].empty?
          i_target = :their
        else
          #run out of conflicts in :their queue
          if d2[:their].empty?
            i_target = :your
          else
            #there are conflicts in both queues. let the target be the earlier one.
            if d2[:your][0][1] <= d2[:their][0][1]
              i_target = :your
            else
              i_target = :their
            end
          end
        end

        j_target = i_target
        k_target = invert_target(i_target) # k_target is opposite of i and j

        
        # we must simultaneously consider all conflicts that overlap within a region. So we will attempt to resolve
        # a single conflict from your or their, but then must also consider all overlapping conflicts from the other set.
        hi = d2[j_target][0][2] #sets the limit as to the max line this conflict will consider
        r2[j_target] << d2[j_target].shift #set r2[j_target] to be the diff from j_target we are considering 
        while d2[k_target].length > 0 && (d2[k_target][0][1] <= hi + 1) #if there are still conflicts in k_target and lo_k <= hi_j +1
          hi_k = d2[k_target][0][2]
          r2[k_target] << d2[k_target].shift # continue to put all overlapping conflicts with k_target onto r2[k_target]
          if hi < hi_k
            hi = hi_k #if the last conflict goes too high, switch the target. 

            j_target = k_target
            k_target = invert_target(k_target)
          end
        end
        lo2 = r2[i_target][ 0][1]
        hi2 = r2[j_target][-1][2]

        # take the corresponding ranges in yourtext lo0...hi0
        # and in theirtext lo1...hi1.
        #
        #   yourtext     ...L!!!!!!!!!!!!!!!!!!!!!!!!!!!!H..
        #   d2[:your]       222    222222222
        #   origtext     ..00!1111!000!!00!111111..
        #   d2[:their]        222222   22  2222222
        #  theirtext          ..L!!!!!!!!!!!!!!!!H..
        if !r2[:your].empty?
          lo0 = r2[:your][ 0][3] - r2[:your][ 0][1] + lo2
          hi0 = r2[:your][-1][4] - r2[:your][-1][2] + hi2
        else
          lo0 = r3[2] - r3[6] + lo2
          hi0 = r3[2] - r3[6] + hi2
        end
        if !r2[:their].empty?
          lo1 = r2[:their][ 0][3] - r2[:their][ 0][1] + lo2
          hi1 = r2[:their][-1][4] - r2[:their][-1][2] + hi2
        else
          lo1 = r3[4] - r3[6] + lo2
          hi1 = r3[4] - r3[6] + hi2
        end

        # detect type of changes
        if r2[:your].empty?
          cmd = '1'
        elsif r2[:their].empty?
          cmd = '0'
        elsif hi0 - lo0 != hi1 - lo1
          cmd = 'A'
        else
          cmd = '2'
          (0 .. hi0 - lo0).each do |d|
            (i0, i1) = [lo0 + d - 1, lo1 + d - 1]
            ok0 = (0 <= i0 && i0 < yourtext.length)
            ok1 = (0 <= i1 && i1 < theirtext.length)
            if (ok0 ^ ok1) || (ok0 && yourtext[i0] != theirtext[i1])
              cmd = 'A'
              break
            end
          end
        end
        result_diff3 << [cmd,  lo0, hi0,  lo1, hi1,  lo2, hi2]
      end

      result_diff3
    end

    def self.merge(yourtext, origtext, theirtext, options={})
      options = DEFAULT_OPTIONS.merge(options)

      trial_res = []

      res = {conflict: 0, body: []}
      d3 = diff3(yourtext, origtext, theirtext)

      text3 = [yourtext, theirtext, origtext]
      i2 = 1
      d3.each do |r3|
        #r3[5] is the line that this new conflict starts
        #put original text from lines i2 ... r3[5] into the resulting body.
        initial_text = []
        (i2 ... r3[5]).each do |lineno|                  # exclusive (...)
          res[:body] << text3[2][lineno - 1]
          initial_text << text3[2][lineno - 1]
        end
        trial_res << {type: :non_conflict, text: initial_text.join("\n"), place: :a}


        if r3[0] == '0'
          # 0 flag means choose yourtext.  put lines r3[1] .. r3[2] into the resulting body.
          temp_text = []
          (r3[1] .. r3[2]).each do |lineno|            # inclusive (..)
            res[:body] << text3[0][lineno - 1]
            temp_text << text3[0][lineno - 1]
          end
          trial_res << {type: :non_conflict, text: temp_text.join("\n"), place: :b}
        elsif r3[0] != 'A'
          # A flag means choose theirtext.  put lines r3[3] to r3[4] into the resulting body.
          temp_text = []
          (r3[3] .. r3[4]).each do |lineno|            # inclusive (..)
            res[:body] << text3[1][lineno - 1]
            temp_text << text3[1][lineno - 1]
          end
          trial_res << {type: :non_conflict, text: temp_text.join("\n"), place: :c}
        else
          res = _conflict_range(text3, r3, res, options, trial_res)
          trial_res = _conflict_range(text3, r3, res, options, trial_res)
        end
        #assign i2 to be the line in origtext after the conflict
        i2 = r3[6] + 1
      end

      #finish by putting all text after the last conflict into the resulting body.
      temp_text = []
      (i2 .. text3[2].length).each do |lineno|         # inclusive (..)
        #res[:body] << text3[2][lineno - 1]
        temp_text << text3[2][lineno - 1]
      end
      trial_res << {type: :non_conflict, text: temp_text.join("\n"), place: :d}

      trial_res
    end

    # Two-way diff based on the algorithm by P. Heckel.
    # @param [in] text_a Array of lines of first text.
    # @param [in] text_b Array of lines of second text.
    # @returns TODO
    def self.diff(text_a, text_b)
      d    = []
      uniq = [[text_a.length, text_b.length]]
      #start building up uniq
      freq, ap, bp = [{}, {}, {}]
      text_a.each_with_index do |line, i| # for each line in text_a
        freq[line] ||= 0
        freq[line] += 2                   # add 2 to the freq of line if its in text_a
        ap  [line] = i                    # set ap[line] to the line number
      end
      text_b.each_with_index do |line, i| # for each line in text_b
        freq[line] ||= 0
        freq[line] += 3                   # add 3 to the freq of line if its in text_b
        bp  [line] = i                    # set bp[line] to the line number
      end
      # only a tupple of [line from a, line from b] to uniq when there is 1 of each line in both texts
      # this ensures that a tuple in uniq shows a place where the texts agree with eachother. 
      freq.each do |line, x|
        if x == 5
          uniq << [ap[line], bp[line]]    # if the line was uniqely in both, add uniq.push([line number in a, line number in b])
        end
      end

      freq, ap, bp = [{}, {}, {}]         # clear freq, ap, ab. Not really necessary, does it save memory?
      uniq.sort!{|a, b| a[0] <=> b[0]}    # sort by the line in which the line was found in a
      a1, b1 = [0, 0]

      # set a1 and b1 to be the first line where there is a conflict.
      while a1 < text_a.length && b1 < text_b.length
        if text_a[a1] != text_b[b1]
          break
        end
        a1 += 1
        b1 += 1
      end

      # uniq.each do |a_uniq, b_uniq|
      #   puts text_a[a_uniq]
      # end

      # start with a1, b1 being the lines before the first conflict.
      # for each pair of lines in uniq which definitely match eachother:
      uniq.each do |a_uniq, b_uniq|
        # puts " "
        # puts "UNIQ.EACH"
        # puts text_a[a_uniq]
        # (a_uniq < a1 || b_uniq < b1) == true guarentees there is not a conflict (since we walked a1 and b1 to conflicts before this section, and at the end of each block)
        # a1 and b1 are always the lines right before the next conflict.
        if a_uniq < a1 || b_uniq < b1
          next
        end
        #a0, b0 are the last agreeing lines before a conflict.
        a0, b0 = [a1, b1]
        # we know a_uniq to be the next line which has a corresponding b_uniq. so a1 = last line of potential conflict (as does b1)
        a1, b1 = [a_uniq - 1, b_uniq - 1]
        # loop from a1 and b1's new positions down towards a0, b0.  stop when there is a conflict.  This gives the bounds of the conflict as [a0,a1] and [b0, b1]
        while a0 <= a1 && b0 <= b1
          if text_a[a1] != text_b[b1]   # a conflict is found on lines a1 and b1.  break out of loop.
            break
          end
          a1 -= 1
          b1 -= 1
        end

        if a0 <= a1 && b0 <= b1 # for this conflict, the bounds are both 'normal'.  the beginning of the conflict is before the end.
          # puts "CCCCC: " + text_a[a1] + " " + text_b[b1]
          # puts text_a[a0+1..a1+1]
          # puts "///////////"
          # puts text_b[b0+1..b1+1]
          d << ['c', a0 + 1, a1 + 1, b0 + 1, b1 + 1]
        elsif a0 <= a1
          # puts "DDDDDD: " + text_a[a1] + " " + text_b[b1]
          # puts text_a[a0+1..a1+1]
          # puts "///////////"
          # puts text_b[b0+1..b0]
          d << ['d', a0 + 1, a1 + 1, b0 + 1, b0]
        elsif b0 <= b1
          # puts "AAAAAA: " + text_a[a1] + " " + text_b[b1]
          # puts text_a[a0+1..a0]
          # puts "///////////"
          # puts text_b[b0+1..b1+1]
          d << ['a', a0 + 1, a0, b0 + 1, b1 + 1]
        end
        #set a1 and b1 to be the words after the matching uniq word
        a1, b1 = [a_uniq + 1, b_uniq + 1]

        # walk a1 and b1 to next conflict spot
        while a1 < text_a.length && b1 < text_b.length
          if text_a[a1] != text_b[b1]
            break
          end
          a1 += 1
          b1 += 1
        end
        # puts "next a1"
        # puts text_a[a1]
        # puts "next b1"
        # puts text_b[b1]
      end

      d
    end

    private
      def self.invert_target(target)
        if target == :your
          :their
        else
          :your
        end
      end

      #only called with certain conflict types:
      def self._conflict_range(text3, r3, res, options, trial_res)
        text_a = [] # conflicting lines in theirtext
        (r3[3] .. r3[4]).each do |i|                   # inclusive(..)
          text_a << text3[1][i - 1]
        end
        text_b = [] # conflicting lines in yourtext
        (r3[1] .. r3[2]).each do |i|                   # inclusive(..)
          text_b << text3[0][i - 1]
        end
        d = diff(text_a, text_b)
        if !_assoc_range(d, 'c').nil? && r3[5] <= r3[6]
          conflict = {type: :conflict, place: :z}
          #res[:conflict] += 1
          #res[:body] << options[:markers][:left]
          ours = []
          (r3[1] .. r3[2]).each do |lineno|
            #res[:body] << text3[0][lineno - 1]
            ours << text3[0][lineno -1]
          end
          conflict[:ours] = ours.join("\n")
          if options[:include_base]
            base = []
            #res[:body] << options[:markers][:base]
            (r3[5] .. r3[6]).each do |lineno|
              #res[:body] << text3[2][lineno - 1]
              base << text3[2][lineno - 1]
            end
            conflict[:base] = base.join("\n")
          end
          #res[:body] << options[:markers][:right]
          theirs = []
          (r3[3] .. r3[4]).each do |lineno|
            #res[:body] << text3[1][lineno - 1]
            theirs << text3[1][lineno - 1]
          end
          conflict[:theirs] = theirs.join("\n")
          trial_res << conflict
          #res[:body] << options[:markers][:close]
          return trial_res
        end

        ia = 1

        d.each do |r2|
          conflict = {}
          common = []
          (ia ... r2[1]).each do |lineno|
            #res[:body] << text_a[lineno - 1]
            common << text_a[lineno - 1]
          end
          #do something with common?
          if r2[0] == 'c'
            #res[:conflict] += 1
            conflict[:type] =  :conflict
            conflict[:place] = :y
            #res[:body] << options[:markers][:left]
            ours = []
            (r2[3] .. r2[4]).each do |lineno|
              #res[:body] << text_b[lineno - 1]
              ours << text_b[lineno - 1]
            end
            conflict[:ours] = ours.join("\n")
            #res[:body] << options[:markers][:right]
            theirs = []
            (r2[1] .. r2[2]).each do |lineno|
              theirs << text_a[lineno - 1]
              #res[:body] << text_a[lineno - 1]
            end
            conflict[:theirs] = theirs.join("\n")
            #res[:body] << options[:markers][:close]
          elsif r2[0] == 'a'
            conflict[:type] = :conflict
            conflict[:place] = :x
            temp_text = []
            (r2[3] .. r2[4]).each do |lineno|
              #res[:body] << text_b[lineno - 1]
              temp_text << text_b[lineno - 1]
            end
            conflict[:text] = temp_text.join("\n")
          end

          ia = r2[2] + 1
          trial_res << conflict
        end

        temp_text = []
        (ia ... text_a.length).each do |lineno|
          #res[:body] << text_a[lineno - 1]
          temp_text << text_a[lineno - 1]
        end
        trial_res << {type: :non_conflict, text: temp_text.join("\n"), place: :e}

        trial_res
      end

      # @param [in] diff        conflicts in diff structure
      # @param [in] diff_type   type of diff looked for in diff
      # @returns diff_type if any conflicts in diff are of type diff_type.  otherwise returns nil
      def self._assoc_range(diff, diff_type)
        diff.each do |d|
          if d[0] == diff_type
            return d
          end
        end

        nil
      end

      # @param [in] conflicts
      # @returns the list of conflicts with contiguous parts merged if they are non_conflicts
      def self.merge_contiguous_non_conflicts(res)
        indices_to_delete = []
        (0 ... res.length).each do |i|
          if res[i][:type] == :non_conflict && res[i+1][:type] == :non_conflict
            res[i][:text] += res[i+1][:text]
            indices_to_delete << i+1
          end
        end
        indices_to_delete.each{ |i| res.delete_at(i)}
      end
  end
end
