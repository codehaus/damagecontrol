module MetaProject
  module Project

    class Base
      def build_tool
        return nil unless scm_web
        
        scm_web.root.children.each do |file|
          return BuildTool::Rake.new if !file.directory? && file.basename =~ /Rakefile/
          return BuildTool::Ant.new  if !file.directory? && file.basename == "build.xml"
        end
        return BuildTool::Unknown.new # Didn't recognise any
      end
      
    end
  end
end