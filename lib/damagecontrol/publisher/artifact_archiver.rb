require 'damagecontrol/publisher/base'
require 'rake'

module DamageControl
  module Publisher
    # Copies build artifacts (files) over to a more permanent location
    # where they can be served via the web server.
    class ArtifactArchiver < Base
      register self

      ann :tip => "Files to archive and make available for download."
      ann :description => "Files"
      attr_accessor :files

      def initialize
        @files = {}
      end

      def name
        "Artifact Archiver"
      end    

      def publish(build)
        @files.each do |src_glob, dest_dir|
          full_dest_dir = Artifact::ROOT_DIR + '/' + dest_dir
          FileUtils.mkdir_p(full_dest_dir)

          full_src = build.revision.project.working_copy_dir + '/' + src_glob
          fl = Rake::FileList.new
          fl.include(full_src)
          fl.to_a.each do |fl_src|
            FileUtils.cp(fl_src, full_dest_dir)
            build.artifacts.create(:relative_path => dest_dir + '/' + File.basename(fl_src))
          end
        end
      end
    end
  end
end

