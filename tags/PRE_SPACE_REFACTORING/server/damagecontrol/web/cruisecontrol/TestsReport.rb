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
        cmd_with_io(Dir.pwd, "xsltproc #{stylesheet_file} #{selected_build.xml_log_file}") do |io|
          io.each_line do |line|
            #puts line
            result += line
          end
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
  end
end