# Classes including this module should represent nodes in a virtual or real
# directory/file hierarchy. They must have the following methods:
#
# +parent+ => FileMethods (representing the parent node)
# +name+ => String (representing the short name of the node)
# +files+ => [FileMethods] (representing the child nodes. First all the dirs, then the files)
#
module FileMethods
  # Array of path components from root
  def path
    parent ? parent.path + [name] : []
  end
  
  # Writes ourself as ascii art
  def ascii(io, depth=0)
    io.write("  ".times(depth))
    io.puts(name)
    
    files.each do |file|
      file.ascii(io, depth+1)
    end
  end
end

class String
  def times(n)
    r = ""
    (0..n).each {|i| r = r + self}
    r
  end
end