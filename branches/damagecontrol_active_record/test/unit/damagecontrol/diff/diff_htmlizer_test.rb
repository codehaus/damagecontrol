require 'test/unit'
require 'fileutils'
require 'rscm/difftool_test'
require 'damagecontrol/diff/diff_parser'
require 'damagecontrol/diff/diff_htmlizer'

module DamageControl
  class DiffHtmlizerTest < Test::Unit::TestCase
    def test_should_parse_diff_to_object_model
      p = DiffParser.new

      html_file = File.dirname(__FILE__) + "/../../../../target/diff.html"
      File.delete(html_file) if File.exist?(html_file)
      FileUtils.mkdir(File.dirname(html_file)) unless File.exist?(File.dirname(html_file))

      File.open(File.dirname(__FILE__) + "/test.diff") do |diff|
        diffs = p.parse_diffs(diff)
        File.open(html_file,"w") do |html|
          hd = DiffHtmlizer.new(html)
          html << "<html>\n"
          html << "<head>\n"
          html << "<link type='text/css' rel='stylesheet' href='../../../../public/stylesheets/diff.css'>\n"
          html << "</head>\n"
          html << "<body>\n"
          diffs.accept(hd)
          html << "</body>\n"
          html << "</html>\n"
        end
      end
      expected = File.open(File.dirname(__FILE__) + "/test.html")
      assert_equal_with_diff(expected.read_fix_nl, File.open(html_file).read_fix_nl)
    end
  end
end

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