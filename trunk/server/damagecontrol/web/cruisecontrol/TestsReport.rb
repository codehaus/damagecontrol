require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/XMLMerger'
require 'pebbles/XSLT'

module DamageControl
  class XSLTReport < Report
    include XSLT
  
    def available?
      super && File.exists?(@build_history_repository.xml_log_file(selected_build.project_name, selected_build.dc_creation_time))
    end
    
    def content
      #xslt(stylesheet_file(stylesheet), selected_build.xml_log_file, "#{selected_build.xml_log_file}.html")
      #File.new("#{selected_build.xml_log_file}.html").read
      "FIXME"
    end
    
  protected

    def stylesheet
      raise "you have to implement #{stylesheet}"
    end

  private

    def stylesheet_file(name)
      File.expand_path("#{template_dir}/#{name}")
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