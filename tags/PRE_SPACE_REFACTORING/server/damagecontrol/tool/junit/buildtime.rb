f = File.open("groovy.txt")
time = 0
f.each do |line|
  if /Time elapsed: (.*) sec/ =~ line
    time = time + $1.to_f
  end
  #puts line
end
puts time