require 'damagecontrol/publisher/base'
require 'rake'

module DamageControl
  module Publisher
    # Copies build artifacts (files) over to a more permanent location
    # where they can be served via the web server.
    class ArtifactArchiver < Base
      register self
      
      ann :tip => "A Hash describing files to archive and make available for download. The source can be a glob, the destination must be a relative path which describes where the artifact(s) will be available from under the DC artifact url. Example: 'target/*.jar' => 'java/picocontainer/jars'. This will make the jar available from http://server:port/artifacts/java/picocontainer/jars/picocontainer-1.3.1298.jar (assuming the build is using DAMAGECONTROL_BUILD_LABEL to name the artifact and the label at the time of build is 1298)"
      ann :description => "Files"
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
          fl = Rake::FileList.new
          fl.include(full_src)
          fl.to_a.each do |fl_src|
            FileUtils.cp(fl_src, Artifact::ROOT_DIR)
            
            dir = Directory.lookup(dest.split("/"), true)
            basename = File.basename(fl_src)
            build.artifacts.create(:name => basename, :directory_id => dir.id, :file_reference => basename)
          end
        end
      end
    end
  end
end
