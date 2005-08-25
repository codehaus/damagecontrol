module MetaProject
  module Project
    module BuildTool
      class Rake
        def build_command
          "rake"
        end

        def artifacts
          {
            "pkg/*.gem" => "gems"
          }
        end
      end
    end
  end
end