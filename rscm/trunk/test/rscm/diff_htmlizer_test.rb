require 'test/unit'
require 'rscm/tempdir'
require 'rscm/diff_parser'
require 'rscm/diff_htmlizer'

module RSCM
  class DiffHtmlizerTest < Test::Unit::TestCase
    def test_should_parse_diff_to_object_model
      p = DiffParser.new

      html_file = "#{RSCM.new_temp_dir}/diff.html"
      File.open(File.dirname(__FILE__) + "/test.diff") do |diff|
        diffs = p.parse_diffs(diff)
        File.open(html_file,"w") do |html|
          hd = DiffHtmlizer.new(html)
          html << "<html>\n"
          html << "<head>\n"
          html << "<link type='text/css' rel='stylesheet' href='../../public/stylesheets/diff.css'>\n"
          html << "</head>\n"
          html << "<body>\n"
          diffs.accept(hd)
          html << "</body>\n"
          html << "</html>\n"
        end
      end
      expected = File.open(File.dirname(__FILE__) + "/test.html")
      assert_equal(expected.read, File.open(html_file).read)
    end
  end
end