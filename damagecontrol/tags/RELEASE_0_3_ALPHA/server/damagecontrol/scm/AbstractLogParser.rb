module DamageControl
  
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
#puts "#{@current_line_number} #{line}"
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
      logger.error(msg + "\ncurrent line: #{@current_line}\nstack trace:\n#{format_backtrace(caller)}")
    end
    
    def had_error?
      @had_error
    end
  end

end