module MetaProject
  module Project

    class Base
      def build_tool
        return nil unless scm_web
        
        scm_web.root.children.each do |file|
          return BuildTool::Rake.new  if !file.directory? && file.basename =~ /Rakefile/
          return BuildTool::Maven.new if !file.directory? && file.basename == "project.xml"
          return BuildTool::Ant.new   if !file.directory? && file.basename == "build.xml"
          return BuildTool::Nant.new  if !file.directory? && file.basename =~ /\.build$/
          return BuildTool::Make.new  if !file.directory? && file.basename == "configure"
        end
        return BuildTool::Unknown.new # Didn't recognise any
      end
      
    end
  end
end