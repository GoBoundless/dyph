module Dyph3
  class Differ
    # Algorithm adapted from http://www.rad.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html

    DEFAULT_OPTIONS = {
      markers: {
      }
    }

    # Three-way diff based on the GNU diff3.c by R. Smith.
    #   @param [in] yourtext    Array of lines of your text.
    #   @param [in] origtext    Array of lines of original text.
    #   @param [in] theirtext   Array of lines of their text.
    #   @returns Array of tuples containing diff results. The tuples consist of
    #        (cmd, loA, hiA, loB, hiB), where cmd is either one of
    #        '0', '1', '2', or 'A'.
    def self.diff3(yourtext, origtext, theirtext)
      # diff result => [(cmd, loA, hiA, loB, hiB), ...]
      d2 = [diff(origtext, yourtext), diff(origtext, theirtext)]
      d3 = []
      r3 = [nil,  0, 0,  0, 0,  0, 0]
      
      while d2[0] || d2[1]
        # find a continual range in origtext lo2..hi2
        # changed by yourtext or by theirtext.
        #
        #     d2[0]        222    222222222
        #  origtext     ...L!!!!!!!!!!!!!!!!!!!!H...
        #     d2[1]          222222   22  2222222
        r2 = [[], []]
        if !d2[0]
          i = 1
        else
          if !d2[1]
            i = 0
          else
            if d2[0][0][1] <= d2[1][0][1]
              i = 0
            else
              i = 1
            end
          end
        end
        j  = i
        k  = i ^ 1   # xor
        hi = d2[j][0][2]
        r2[j] << d2[j].pop
        while d2[k] && (d2[k][0][1] <= hi + 1)
          hi_k = d2[k][0][2]
          r2[k] << d2[k].pop
          if hi < hi_k
            hi = hi_k
            j  = k
            k  = k ^ 1      # xor
          end
        end
        lo2 = r2[i][ 0][1]
        hi2 = r2[j][-1][2]
        
        # take the corresponding ranges in yourtext lo0..hi0
        # and in theirtext lo1..hi1.
        #
        #   yourtext     ..L!!!!!!!!!!!!!!!!!!!!!!!!!!!!H...
        #      d2[0]        222    222222222
        #   origtext     ...00!1111!000!!00!111111...
        #      d2[1]          222222   22  2222222
        #  theirtext          ...L!!!!!!!!!!!!!!!!H...
        if r2[0]
          lo0 = r2[0][ 0][3] - r2[0][ 0][1] + lo2
          hi0 = r2[0][-1][4] - r2[0][-1][2] + hi2
        else
          lo0 = r3[2] - r3[6] + lo2
          hi0 = r3[2] - r3[6] + hi2
        end
        if r2[1]
          lo1 = r2[1][ 0][3] - r2[1][ 0][1] + lo2
          hi1 = r2[1][-1][4] - r2[1][-1][2] + hi2
        else
          lo1 = r3[4] - r3[6] + lo2
          hi1 = r3[4] - r3[6] + hi2
        end
        
        # detect type of changes
        if !r2[0]
          cmd = '1'
        elsif not r2[1]
          cmd = '0'
        elsif hi0 - lo0 != hi1 - lo1
          cmd = 'A'
        else
          cmd = '2'
          for d in range(0, hi0 - lo0 + 1)
            (i0, i1) = [lo0 + d - 1, lo1 + d - 1]
            ok0 = (0 <= i0 && i0 < yourtext.length)
            ok1 = (0 <= i1 && i1 < theirtext.length)
            if (ok0 ^ ok1) || (ok0 && yourtext[i0] != theirtext[i1])
              cmd = 'A'
              break
            end
          end
        end
        d3 << [cmd,  lo0, hi0,  lo1, hi1,  lo2, hi2]
      end
      
      d3
    end
    
    def self.merge(yourtext, origtext, theirtext)
      res = {conflict: 0, body: []}
      d3 = diff3(yourtext, origtext, theirtext)
      text3 = [yourtext, theirtext, origtext]
      i2 = 1
      d3.each do |r3|
        (i2 .. r3[5]).each do |lineno|                  # exclusive (..)
          res[:body] << text3[2][lineno - 1]
        end
        
        if r3[0] == '0'
          (r3[1] ... r3[2]).each do |lineno|            # inclusive (...)
            res[:body] << text3[0][lineno - 1]
          end
        elsif r3[0] != 'A'
          (r3[3] ... r3[4]).each do |lineno|            # inclusive (...)
            res[:body] << text3[1][lineno - 1]
          end
        else
          res = _conflict_range(text3, r3, res)
        end
        i2 = r3[6] + 1
      end
      
      (i2 ... text3[2].length).each do |lineno|         # inclusive (...)
        res[:body] << text3[2][lineno - 1]
      end
      
      res
    end
    
    # Two-way diff based on the algorithm by P. Heckel.
    # @param [in] text_a Array of lines of first text.
    # @param [in] text_b Array of lines of second text.
    # @returns TODO
    def self.diff(text_a, text_b)
      d    = []
      uniq = [[text_a.length, text_b.length]]
      
      (freq, ap, bp) = [{}, {}, {}]
      text_a.length.times do |i|
        s = text_a[i]
        freq[s] ||= 0
        freq[s] += 2
        ap  [s] = i
      end
      text_b.length.times do |i|
        s = text_b[i]
        freq[s] ||= 0
        freq[s] += 3
        bp  [s] = i
      end
      freq.each do |s, x|
        if x == 5
          uniq << [ap[s], bp[s]]
        end
      end
      
      (freq, ap, bp) = [{}, {}, {}]
      uniq.sort!{|a, b| a[0] <=> b[0]}
      (a1, b1) = [0, 0]
      while a1 < text_a.length && b1 < text_b.length
        if text_a[a1] != text_b[b1]
          break
        end
        a1 += 1
        b1 += 1
      end
      
      uniq.each do |a_uniq, b_uniq|
        if a_uniq < a1 || b_uniq < b1
          next
        end
        (a0, b0) = [a1, b1]
        (a1, b1) = [a_uniq - 1, b_uniq - 1]
        while a0 <= a1 && b0 <= b1
          if text_a[a1] != text_b[b1]
            break
          end
          a1 -= 1
          b1 -= 1
        end
        if a0 <= a1 && b0 <= b1
          d << ['c', a0 + 1, a1 + 1, b0 + 1, b1 + 1]
        elsif a0 <= a1
          d << ['d', a0 + 1, a1 + 1, b0 + 1, b0]
        elsif b0 <= b1
          d << ['a', a0 + 1, a0, b0 + 1, b1 + 1]
        end
        (a1, b1) = [a_uniq + 1, b_uniq + 1]
        while a1 < text_a.length && b1 < text_b.length
          if text_a[a1] != text_b[b1]
            break
          end
          a1 += 1
          b1 += 1
        end
      end
      
      d
    end

    private
      def self._conflict_range(text3, r3, res)
        text_a = [] # their text
        (r3[3] ... r3[4]).each do |i|                   # inclusive(...)
          text_a << text3[1][i - 1]
        end
        text_b = [] # your text
        (r3[1] ... r3[2]).each do |i|                   # inclusive(...)
          text_b << text3[0][i - 1]
        end
        d = diff(text_a, text_b)
        if _assoc_range(d, 'c') && r3[5] <= r3[6]
          res[:conflict] += 1
          res[:body] << '<<<<<<<'
          (r3[1] ... r3[2]).each do |lineno|
            res[:body] << text3[0][lineno - 1]
          end
          res[:body] << '|||||||'
          (r3[5] ... r3[6]).each do |lineno|
            res[:body] << text3[2][lineno - 1]
          end
          res[:body] << '======='
          (r3[3] ... r3[4]).each do |lineno|
            res[:body] << text3[1][lineno - 1]
          end
          res[:body] << '>>>>>>>'
          return res
        end
        
        ia = 1
        d.each do |r2|
          (ia .. r2[1]).each do |lineno|
            res[:body] << text_a[lineno - 1]
          end
          if r2[0] == 'c'
            res[:conflict] += 1
            res[:body] << '<<<<<<<'
            (r2[3] ... r2[4]).each do |lineno|
              res[:body] << text_b[lineno - 1]
            end
            res[:body] << '======='
            (r2[1] ... r2[2]).each do |lineno|
              res[:body] << text_a[lineno - 1]
            end
            res[:body] << '>>>>>>>'
          elsif r2[0] == 'a'
            (r2[3] ... r2[4]).each do |lineno|
              res[:body] << text_b[lineno - 1]
            end
          end
          ia = r2[2] + 1
        end
        
        (ia .. text_a.length).each do |lineno|
          res[:body] << text_a[lineno - 1]
        end
        
        res
      end
      
      def self._assoc_range(diff, diff_type)
        diff.each do |d|
          if d[0] == diff_type
            return d
          end
        end
        
        nil
      end
  end
end
