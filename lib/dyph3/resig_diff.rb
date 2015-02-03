module Dyph3
  class ResigDiff
    def self.diff(text_a, text_b)
      o = text_a.dup
      n = text_b.dup

      ns, os = [{}, {}]

      n.each_with_index do |text, i|
        if ns[text].nil?
          ns[text] = { rows: [], o: nil }
        end
        ns[text][:rows] << i
      end

      o.each_with_index do |text, i|
        if os[text].nil?
          os[text] = { rows: [], n: nil }
        end
        os[text][:rows] << i
      end

      ns.keys.each do |i|
        if (!os[i].nil? && ns[i][:rows].length == 1 && os[i][:rows].length == 1)
          n[ ns[i][:rows][0] ]  = TextNode.new(text: n[ ns[i][:rows][0]], row: os[i][:rows][0])
          o[ os[i][:rows][0] ]  = TextNode.new(text: o[ os[i][:rows][0]], row: ns[i][:rows][0])
        end
      end

      (0 ... n.length).each do |i|
        if first_fucking_crazy_check(n, o, i)
          n[i+1]          = TextNode.new(text: n[i+1], row: n[i][:row] + 1)
          o[n[i].row + 1] = TextNode.new(text: o[n[i][:row]+1], row: i + 1)
        end
      end

      (n.length - 1).downto(0).each do |i|
        if second_fucking_crazy_check(n, o, i)
          n[i-1]          = TextNode.new(text: n[i-1], row: n[i][:row] - 1)
          o[n[i].row - 1] = TextNode.new(text: o[n[i][:row]- 1], row: i - 1)
        end
      end
      convert_to_merge_format result: { o: o, n: n}
    end

    def self.convert_to_merge_format(result: )
      binding.pry
      result
    end
    #n[i].text != null && n[i+1].text == null && n[i].row + 1 < o.length && o[ n[i].row + 1 ].text == null && n[i+1] == o[ n[i].row + 1 ] )
    def self.first_fucking_crazy_check(n, o, i)
      n[i].respond_to?(:text) && !n[i].text.nil? && #n[i].text != null
      (!n[i+1].respond_to?(:text) || n[i+1].text.nil?) && #n[i+1].text == null
      n[i].row + 1 < o.length &&
      (!o[n[i].row + 1].respond_to?(:text) ||  o[n[i].row + 1].text.nil?) && #o[ n[i].row + 1 ].text == null
      n[i+1] == o[ n[i].row + 1 ]
    end

    def self.second_fucking_crazy_check(n, o, i)
      n[i].respond_to?(:text) && !n[i].text.nil? && #n[i].text != null
      (!n[i-1].respond_to?(:text) || n[i-1].text.nil?) && #n[i-1].text == null
      n[i].row > 0 &&
      (!o[n[i].row - 1].respond_to?(:text) ||  o[n[i].row - 1].text.nil?) && #o[ n[i].row - 1 ].text == null
      n[i-1] == o[ n[i].row - 1 ]
    end
  end
  
  

  class TextNode
    attr_accessor :text, :row

    def initialize(text: , row:)
      @text = text
      @row = row
    end

  end
end