require 'rscm/logging'
require 'damagecontrol/revision_ext.rb'

module DamageControl
  module Visitor

    # Visitor that persists unified diffs to disk.
    #
    class DiffPersister
      def visit_revisions(revisions)
      end

      def visit_revision(revision)
        @revision = revision
      end

      def visit_file(file)
        file.revision = @revision unless file.revision
        diff_file = file.diff_file
        FileUtils.mkdir_p(File.dirname(diff_file))
        file.revision.project.scm.diff(file) do |diff_io|
          File.open(diff_file, "w") do |io|
            diff_io.each_line do |line|
              io.write(line)
            end
          end
        end
        Log.info "Wrote diff for #{file.path} -> #{diff_file}"
      end

    end
  end
end
