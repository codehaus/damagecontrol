module MetaProject
  module Project
    module BuildTool
      class Maven
        def build_command
          "maven"
        end

        def artifacts
          {
            "target/**/*.jar" => "jars" # TODO: make it appear somewhere according to maven/ibiblio structure
          }
        end
      end
    end
  end
end