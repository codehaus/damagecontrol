q = BuildQueue.new
while(true)
  build = q.next
  build.execute
end