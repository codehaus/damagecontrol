module RSCM

  # Visitor that can visit an array of diffs and produce nice HTML
  # TODO: add line numbers.
  class DiffHtmlizer
    # Creates a new DiffHtmlizer that will write HTML
    # to the IO object +io+ when visiting an array of diffs.
    def initialize(io)
      @io = io
    end
    
    def visitDiff(diff)
      @io << "<div>\n"
    end

    def visitDiffEnd(diff)
      @io << "</div>\n"
    end
    
    def visitLine(line)
      if(line.removed?)
        @io << "<pre class='diff' id='removed'>"
        if(line.removed)
          @io << line.prefix.html_encoded
          @io << "<span id='removedchars'>"
          @io << line.removed.html_encoded
          @io << "</span>"
          @io << line.suffix.html_encoded
        else
          @io << line.html_encoded
        end
        @io << "</pre>"
      elsif(line.added?)
        @io << "<pre class='diff' id='added'>"
        if(line.added)
          @io << line.prefix.html_encoded
          @io << "<span id='addedchars'>"
          @io << line.added.html_encoded
          @io << "</span>"
          @io << line.suffix.html_encoded
        else
          @io << line.html_encoded
        end
        @io << "</pre>"
      else
        @io << "<pre class='diff' id='context'>"
        @io << line.html_encoded
        @io << "</pre>"
      end
    end
  end

  # Not used
  class Plain
    def initialize(io)
      @io = io
    end
    
    def visitDiff(diff)
    end

    def visitDiffEnd(diff)
    end
    
    def visitLine(line)
      @io << line.html_encoded
    end
  end
end

class String
  def html_encoded
    self.gsub(/./) do
      case $&
        when "&" then "&amp;"
        when "<" then "&lt;"
        when ">" then "&gt;"
        else $&
      end
    end
  end
end
