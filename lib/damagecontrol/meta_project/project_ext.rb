module MetaProject
  module Project

    class Base
      # TODO: look at the scm_web to figure out what build tool to use!
      def build_tool
        BuildTool::Ant.new
      end
      
    end
  end
end