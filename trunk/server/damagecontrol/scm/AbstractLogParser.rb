module DamageControl
  
  # Some utilities for log-parsers
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
      logger.error(msg + "\ncurrent line: #{@current_line}\ncvs log:\n#{@log}#{format_backtrace(caller)}")
    end
    
    def had_error?
      @had_error
    end
  end

end