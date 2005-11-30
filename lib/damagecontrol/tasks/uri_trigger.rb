require 'open-uri'
require 'time'

class UriTrigger
  attr_accessor :uri
  attr_accessor :time_regexp
  
  # Returns true if the contents at +uri+ have changed since +since+
  def modified?(since)
    Kernel.open(uri) do |io|
      t = time(io)
      if(t.nil? && time_regexp.is_a?(Regexp))
        if(io.read =~ time_regexp)
          t = Time.parse($1)
        end
      end
      
      if(t)
        return t > since
      else
        "No time"
      end
    end
  end
  
private
  
  def time(io)
    return io.last_modified if io.respond_to?(:last_modified)
    return io.mtime if io.respond_to?(:mtime)
    nil
  end
end

t = UriTrigger.new
t.uri = "http://contractll004.llbean.com:8080/cruisecontrol/buildresults/merchandise-planning-subversion"
t.time_regexp = /<th>Date of build:<\/th><td>(\d\d\/\d\d\/\d\d\d\d \d\d:\d\d:\d\d)<\/td>/
#t.uri = __FILE__
m = t.modified?(Time.utc(2002))
puts "modified: #{m}"