module DamageControl

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

  # Represents a unified diff section in a diff file.
  class Diff
    attr_reader :minus, :nminus, :plus, :nplus, :removed_range

    # Create a new Diff. +minus+ and +plus+ represent the number of
    # removed and added lines.
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
        prefix_length = 1
        suffix_len = 0
        if(prev && prev.removed? && line.added?)
          a = line[1..-1]
          b = prev[1..-1]
          prefix_length = a.common_prefix_length(b)+1
          suffix_len = a.reverse.common_prefix_length(b.reverse)
          # prevent prefix/suffix having overlap,
          suffix_len = min(suffix_len, min(line.length, prev.length)-prefix_length)
          remove_infix_length = prev.length - (prefix_length+suffix_len)
          add_infix_length = line.length - (prefix_length+suffix_len)
          oversize_change = remove_infix_length*100/prev.length>33 || add_infix_length*100/line.length>33

          if(prefix_length==1 && suffix_len==0 || remove_infix_length<=0 || oversize_change)
          else
            prev.removed_range = (prefix_length..prefix_length+remove_infix_length-1)
          end

          if(prefix_length==1 && suffix_len==0 || add_infix_length<=0 || oversize_change)
          else
            line.added_range = (prefix_length..prefix_length+add_infix_length-1)
          end
        end
        prev = line
      end
    end
    
    def accept(visitor)
      @lines.each do |line|
        visitor.visitLine(line)
      end
    end

  private
  
    def min(a, b)
      a<b ? a : b
    end
  end

end

# Extra methods added to String to ease diff manipulation
class String
  attr_accessor :removed_range
  attr_accessor :added_range

  def removed?
    (self =~ /\-/) == 0
  end

  def removed
    removed_range ? self[removed_range] : nil
  end

  def added?
    (self =~ /\+/) == 0
  end

  def added
    added_range ? self[added_range] : nil
  end

  def prefix
    self[0..range.first-1]
  end

  def suffix
    self[range.last+1..-1]
  end

  def content
    "\n" == self ? "\n" : self[1..-1]
  end

  def common_prefix_length(o)
    length = 0
    each_byte do |char|
      break unless o[length] == char
      length = length + 1
    end
    length
  end

private

  def range
    removed? ? removed_range : added_range
  end

end

# Add visiting capabilities to Array
class Array
  def accept(visitor)
    each do |diff| 
      visitor.visitDiff(diff)
      diff.accept(visitor)
      visitor.visitDiffEnd(diff)
    end
  end
end