class String
  attr_accessor :removed_range

  def removed?
    (self =~ /\-/) == 0
  end

  def added?
    (self =~ /\+/) == 0
  end

  def content
    "\n" == self ? "\n" : self[1..-1]
  end

  def common_prefix_length(o)
    o = o.content
    length = 0
    content.each_byte do |char|
      break unless o[length] == char
      length = length + 1
    end
    length
  end
end

module RSCM

  class Diff
    attr_reader :minus, :nminus, :plus, :nplus, :removed_range

    def initialize(minus, nminus, plus, nplus)
      @minus, @nminus, @plus, @nplus = minus, nminus, plus, nplus
      @lines = []
    end
    
    def <<(line)
      @lines << line
    end
    
    def line_count
      @lines.length
    end
    
    def[](n)
      @lines[n]
    end
    
    def parse
      prev = nil
      @lines.each do |line|
        if(prev && prev.removed? && line.added?)
          cpl = line.common_prefix_length(prev)
          puts cpl
        end
        prev = line
      end
    end
  end

  class DiffParser

    DIFF_START = /@@ \-([0-9]+),([0-9]+) \+([0-9]+),([0-9]+) @@/
  
    def parse_diffs(io)
      diffs = []
      diff = nil
      io.each_line do |line|
        if(line =~ DIFF_START)
          diffs << diff if diff
          diff = Diff.new($1.to_i, $2.to_i, $3.to_i, $4.to_i)
        elsif(diff)
          diff << line
        end
      end
      diffs << diff if diff
      diffs.each do |diff|
        diff.parse
      end
      diffs
    end
  
  end
end
