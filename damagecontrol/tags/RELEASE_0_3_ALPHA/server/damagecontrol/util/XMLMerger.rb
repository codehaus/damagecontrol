module DamageControl
  class XMLMerger
    def initialize(tag, output)
      @output = output
      @tag = tag
      @output.puts(xml_header)
      @output.puts("<#{@tag}>")
    end
    
    def XMLMerger.open(*args)
      m = self.new(*args)
      begin
        yield(m)
      ensure
        m.close
      end
    end
    
    def xml_header
      "<?xml version='1.0'?>"
    end
    
    def merge(io)
      read_until_start_of_body(io)
      io.each_line do |line|
        @output.write(line)
      end
    end

    def read_until_start_of_body(io)
      io.each_line do |line|
        if line =~ /.*?(<\w+?.*)/
          @output.puts($1)
          return
        end
      end
    end
    
    def close
      @output.puts("</#{@tag}>")
      @output.close
    end
  end
end