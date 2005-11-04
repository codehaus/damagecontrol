require 'damagecontrol/publisher/base'
require 'rake'

module DamageControl
  module Publisher
    # Copies build artifacts (files) over to a more permanent location
    # where they can be served via the web server.
    class ArtifactArchiver < Base

      attr_accessor :files

      def initialize
        @files = {}
      end

      def publish(build)
        # only the 1st artifact of each build will be considered 'primary'
        # and will be made available as an <enclosure> in the RSS feed (Appcast).
        is_primary = true
        @files.each do |src_glob, dest_dir|
          full_dest_dir = Artifact::ARTIFACT_DIR + '/' + dest_dir
          FileUtils.mkdir_p(full_dest_dir)

          full_src = build.revision.project.working_copy_dir + '/' + src_glob
          fl = Rake::FileList.new
          fl.include(full_src)
          fl.to_a.each do |fl_src|
            # TODO: add support for copying of directories
            FileUtils.cp(fl_src, full_dest_dir)
            build.artifacts.create(
              :relative_path => dest_dir + '/' + File.basename(fl_src),
              :is_primary => is_primary
            )
            is_primary = false
          end
        end
      end
    end
  end
end

