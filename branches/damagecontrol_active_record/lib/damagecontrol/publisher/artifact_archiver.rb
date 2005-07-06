require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    # Copies build artifacts (files) over to a more permanent location
    # where they can be served via the web server.
    class ArtifactArchiver < Base
      ROOT_DIR = "#{DAMAGECONTROL_HOME}/artifacts"
      FileUtils.mkdir_p(ROOT_DIR) unless File.exist?(ROOT_DIR)

      register self      
      attr_accessor :files
      
      def initialize
        @files = {}
      end

      def name
        "Artifact Archiver"
      end    

      def publish(build)
        @files.each do |src, dest|
          full_src = build.revision.project.working_copy_dir + '/' + src
          full_dest = ROOT_DIR + '/' + dest

          FileUtils.mkdir_p(full_dest)
          FileUtils.cp(full_src, full_dest)
        end
      end
    end
  end
end