require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'

module DamageControl
  class TestResultReport < Report
    include FileUtils
    
    def id
      "tests"
    end
    
    def available?
      selected_build.archive_dir && File.exists?(selected_build.archive_dir) && !xml_files.empty?
    end
    
    def content
      xslt(stylesheet("unittests.xsl"))
    end
    
    def title
      "Test results"
    end
    
    def extra_css
      ["css/cruisecontrol.css"]
    end
    
    def stylesheet(name)
      File.expand_path("#{template_dir}/cruisecontrol/#{name}")
    end
    
    def xml_files
      Dir["#{selected_build.archive_dir}/*.xml"]
    end
    
    def xslt(stylesheet)
      result = ""
      xml_files.each do |file|
        puts "xsltproc #{stylesheet} #{file}"
        cmd_with_io(Dir.pwd, "xsltproc #{stylesheet} #{file}") do |out|
          out.each_line do |line|
            puts line
            result += line
          end
        end
      end
      result
    end
    
  end
end