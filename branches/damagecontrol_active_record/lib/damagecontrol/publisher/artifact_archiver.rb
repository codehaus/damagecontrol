module DamageControl
  module Publisher
    class ArtifactArchiver < Base
      DAMAGECONTROL_ARTIFACTS = "#{DAMAGECONTROL_HOME}/artifacts"
      FileUtils.mkdir_p(DAMAGECONTROL_ARTIFACTS) unless File.exist?(DAMAGECONTROL_ARTIFACTS)

      register self
      attr_accessor :files
      
      def initialize
        @files = {}
      end

      def name
        "ArtifactArchiver"
      end    

      def publish(build)
        
        @files.each do |src, dest|
          full_src = build.revision.project.working_copy_dir + '/' + src
          full_dest = DAMAGECONTROL_ARTIFACTS + '/' + dest

          FileUtils.mkdir_p(full_dest)
          puts "#{full_src} -> #{full_dest}"
          FileUtils.cp(full_src, full_dest)
        end
      end
    end
  end
end