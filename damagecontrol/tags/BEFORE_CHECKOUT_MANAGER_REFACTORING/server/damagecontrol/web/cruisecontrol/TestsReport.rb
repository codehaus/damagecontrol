require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/XMLMerger'

module DamageControl
  class XSLTReport < Report
    def available?
      selected_build.xml_log_file && File.exists?(selected_build.xml_log_file)
    end
    
    def content
      xslt(stylesheet_file(stylesheet))
    end
    
    protected
    
      def stylesheet
        raise "you have to implement #{stylesheet}"
      end
    
    private
      
      def stylesheet_file(name)
        File.expand_path("#{template_dir}/#{name}")
      end
      
      def xslt(stylesheet_file)
        result = ""
        begin
          cmd_with_io("#{damagecontrol_home}/bin", "xsltproc '#{stylesheet_file}' '#{selected_build.xml_log_file}'") do |io|
            io.each_line do |line|
              result += line
            end
          end
        rescue Pebbles::ProcessFailedException => e
          logger.error(format_exception(e))
          result += "Error executing XSLT process: #{e.message}\n"
          result += %{
This could happen for the following reasons:
  xsltproc is not installed properly, or
  might not be on the path, or
  might be of a version that is incompatible with DamageControl.}
        end
        result
      end
      
  end
  
  class CruiseControlReport < XSLTReport
    def id
      File.basename(stylesheet, ".xsl")
    end
    
    def stylesheet_file(name)
      File.expand_path("#{template_dir}/cruisecontrol/#{name}")
    end
      
    def extra_css
      ["css/cruisecontrol.css"]
    end
  end
  
  class TestsReport < CruiseControlReport
    include FileUtils
    
    def stylesheet
      "unittests.xsl"
    end
    
    def title
      "Tests"
    end

    def icon
      return "smallicons/bug_green.png" if(content =~ /All Tests Passed/)
      return "smallicons/bug_yellow.png" if(content =~ /No Tests Run/)
      return "smallicons/bug_red.png"
    end
  end
end