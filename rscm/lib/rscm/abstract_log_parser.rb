module RSCM
  
  # NOTE: It is recommended to use the Parser class in parser.rb
  # as a basis for new SCM parsers
  #
  # Some utilities for log-parsers
  # TODO: make this a module and remove the attr_reader
  class AbstractLogParser
  
    def initialize(io)
      @io = io
    end
  
    def read_until_matching_line(regexp)
      return nil if @io.eof?
      result = ""
      @io.each_line do |line|
        line.gsub!(/\r\n$/, "\n")
        break if line =~ regexp
        result << line
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
    
  end

end