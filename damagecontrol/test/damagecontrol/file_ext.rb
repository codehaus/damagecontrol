class File
  def read_fix_nl
    result = ""
    self.each_line do |line|
      chomped = line.chomp
      result << chomped
      result << "\n" if chomped != line
    end
    result
  end
end

