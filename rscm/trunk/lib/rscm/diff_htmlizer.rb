module RSCM

  # Visitor that can visit an array of diffs and produce nice HTML
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
          @io << line.prefix
          @io << "<span id='removedchars'>"
          @io << line.removed
          @io << "</span>"
          @io << line.suffix
        else
          @io << line
        end
        @io << "</pre>"
      elsif(line.added?)
        @io << "<pre class='diff' id='added'>"
        if(line.added)
          @io << line.prefix
          @io << "<span id='addedchars'>"
          @io << line.added
          @io << "</span>"
          @io << line.suffix
        else
          @io << line
        end
        @io << "</pre>"
      else
        @io << "<pre class='diff' id='context'>"
        @io << line
        @io << "</pre>"
      end
    end
  end

  class Plain
    def initialize(io)
      @io = io
    end
    
    def visitDiff(diff)
    end

    def visitDiffEnd(diff)
    end
    
    def visitLine(line)
      @io << line
    end
  end
end
