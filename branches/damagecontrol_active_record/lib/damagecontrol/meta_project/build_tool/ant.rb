module MetaProject
  module Project
    module BuildTool
      class Ant
        def build_command
          "ant"
        end
        
        def artifacts
          {
            "target/**/*.jar" => "jars",
            "build/**/*.jar" => "jars"
          }
        end
      end
    end
  end
end