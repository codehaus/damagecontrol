require 'tempfile'

module Pebbles
  module LineEditor
    def uncomment(original, line_regex, comment_template, output)
      already_commented_exp = /^[#{comment_template}]/ unless comment_template.nil?
      original.each_line do |line|
        out_line = nil
        if(line_regex =~ line)
          if(already_commented_exp && already_commented_exp =~ line)
            out_line = line
          else
            out_line = "#{comment_template}#{line}" unless comment_template.nil?
          end
        else
          out_line = line
        end
        output << out_line unless out_line.nil?
      end
    end
    module_function :uncomment
  end
end

class File

  def File.uncomment(path, line_regex, comment_template)
    temp_file = Tempfile.new(File.basename(path))
    temp_file_path = temp_file.path
    original = File.new(path)
    Pebbles::LineEditor.uncomment(original, line_regex, comment_template, temp_file)

    temp_file.close
    original.close

    File.copy(temp_file_path, path)
  end
end