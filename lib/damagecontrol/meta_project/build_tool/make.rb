module MetaProject
  module Project
    module BuildTool
      class Make
        def build_command
          "./configure;make"
        end

        def artifacts
          {
          }
        end
      end
    end
  end
end