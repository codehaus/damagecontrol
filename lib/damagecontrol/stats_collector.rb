RAILS_STATS_LOC_TOTAL     = /\|\s+Total\s+\|\s+\d+\s+\|\s+(\d+)\s+\|/
RAILS_STATS_CLASSES_TOTAL = /\|\s+Total\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+(\d+)\s+\|/
RAILS_STATS_METHODS_TOTAL = /\|\s+Total\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+\d+\s+\|\s+(\d+)\s+\|/

data = File.open(ARGV[0]).read
[RAILS_STATS_LOC_TOTAL, RAILS_STATS_CLASSES_TOTAL, RAILS_STATS_METHODS_TOTAL].each do |regexp|
  if(data =~ regexp)
    puts $1
   else
    puts "ERROR, didn't match #{regexp}"
  end
end

class FileStat
  attr_accessor :path, regexp, description
  
  def value
  end
end