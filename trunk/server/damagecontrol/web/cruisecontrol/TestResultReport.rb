require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/util/XMLMerger'

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
    
    def merged_file
      "#{selected_build.archive_dir}.xml"
    end
    
    def is_out_of_date?(output, inputs)
      return true unless File.exists?(output)
      newest_input = inputs.collect{|f| File.mtime(f)}.max
      newest_input > File.mtime(output)
    end 
    
    def if_out_of_date(output, inputs)
      yield if is_out_of_date?(output, inputs)
    end
    
    def create_merged_file
      if_out_of_date(merged_file, xml_files) do
        XMLMerger.open("damagecontrol", File.open(merged_file, "w+")) do |m|
          xml_files.each do |file|
            File.open(file) do |xml_io|
              m.merge(xml_io)
            end
          end
        end
      end
    end
    
    def xslt(stylesheet)
      create_merged_file
      result = ""
      cmd_with_io(Dir.pwd, "xsltproc #{stylesheet} #{merged_file}") do |io|
        io.each_line do |line|
          #puts line
          result += line
        end
      end
      result
    end
    
  end
end