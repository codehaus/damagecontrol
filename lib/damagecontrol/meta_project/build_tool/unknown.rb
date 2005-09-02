module MetaProject
  module Project
    module BuildTool
      class Unknown
        def build_command
          "echo \"DamageControl couldn't guess the build command\""
        end

        def artifacts
          {}
        end
      end
    end
  end
end