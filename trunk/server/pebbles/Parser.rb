module Pebbles
  class Parser
  
    def initialize(break_regexp)
      @break_regexp = break_regexp
    end
  
    def parse(io, skip_line_parsing=false, &line_proc)
      parse_until_regexp_matches(io, skip_line_parsing, &line_proc)
      if(skip_line_parsing)
        nil
      else
        next_result
      end
    end

  protected

    def parse_line(line)
      raise "Must override parse_line(line)"
    end

    def next_result
      raise "Must override next_result(line)"
    end
    
  private

    def parse_until_regexp_matches(io, skip_line_parsing, &line_proc)
      io.each_line { |line|
        yield line if block_given?
        if line =~ @break_regexp
          return
        end
        parse_line(line) unless skip_line_parsing
      }
    end
  end
end