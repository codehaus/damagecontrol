module MetaProject
  module Project
    module XForge
      class RubyForge
        def build_command
          "rake"
        end
        
        def publishers
          artifact_archiver = DamageControl::Publisher::ArtifactArchiver.new
          artifact_archiver.files = {"pkg/*.gem", "rubygems"}
          artifact_archiver.enabling_states = [Build::Successful.new, Build::Fixed.new]
          
          # TODO: add mailing lists here
          [artifact_archiver]
        end
      end
    end
  end
end