module RSCM
  
  # NOTE: It is recommended to use the Parser class in parser.rb
  # as a basis for new SCM parsers
  #
  # Some utilities for log-parsers
  # TODO: make this a module and remove the attr_reader
  class AbstractLogParser
  
    attr_reader :io
  
    def initialize(io)
      @io = io
      @current_line_number = 0
      @had_error = false
    end
  
    def read_until_matching_line(regexp)
      return nil if io.eof?
      result = ""
      io.each_line do |line|
        @current_line_number += 1
        line.gsub!(/\r\n$/, "\n")
        break if line=~regexp
        result<<line
      end
      if result.strip == ""
        read_until_matching_line(regexp) 
      else
        result
      end
    end
    
    def convert_all_slashes_to_forward_slashes(file)
      file.gsub(/\\/, "/")
    end
    
    def error(msg)
      @had_error=true
      $stderr.puts(msg + "\ncurrent line: #{@current_line}\nstack trace:\n")
      $stderr.puts(caller.backtrace.join('\n\t'))
    end
    
    def had_error?
      @had_error
    end
  end

end