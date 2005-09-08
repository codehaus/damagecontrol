module MetaProject
  module Project
    module BuildTool
      class Rake
        def build_command
          "nant"
        end

        def artifacts
          {
            "build/**/*.exe" => "exes",
            "build/**/*.dll" => "exes"
          }
        end
      end
    end
  end
end