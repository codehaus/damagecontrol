require 'tempfile'
require 'ftools'

module RSCM
  module LineEditor
    # Comments out line by line if they match the line_regex.
    # Does not comment out already commented out lines.
    # If comment_template is nil, the matching lines will be deleted
    # Returns true if at least one line is commented out or changed
    def comment_out(original, line_regex, comment_template, output)
      did_comment_out = false
      already_commented_exp = /^[#{comment_template}]/ unless comment_template.nil?
      original.each_line do |line|
        out_line = nil
        if(line_regex =~ line)
          if(already_commented_exp && already_commented_exp =~ line)
            out_line = line
          else
            did_comment_out = true
            out_line = "#{comment_template}#{line}" unless comment_template.nil?
          end
        else
          out_line = line
        end
        output << out_line unless out_line.nil?
      end
      did_comment_out
    end
    module_function :comment_out
  end
end

class File

  def File.comment_out(path, line_regex, comment_template)
    temp_file = Tempfile.new(File.basename(path))
    temp_file_path = temp_file.path
    original = File.new(path)
    RSCM::LineEditor.comment_out(original, line_regex, comment_template, temp_file)

    temp_file.close
    original.close

    File.copy(temp_file_path, path)
  end
end