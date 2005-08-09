class Pathname
  TYPES = Hash.new("application/octet-stream")

  def type
    TYPES[extname]
  end
end