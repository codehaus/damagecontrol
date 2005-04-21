require 'rscm/changes'
require 'rscm/logging'
require 'damagecontrol/changeset_ext.rb'

module DamageControl
  module Visitor

    # Visitor that persists unified diffs to disk.
    #
    class DiffPersister
      def visit_changesets(changesets)
      end

      def visit_changeset(changeset)
        @changeset = changeset
      end

      def visit_change(change)
        change.changeset = @changeset
        diff_file = change.diff_file
        change.changeset.project.scm.diff(change) do |diff_io|
          FileUtils.mkdir_p(File.dirname(diff_file))
          File.open(diff_file, "w") do |io|
            diff_io.each_line do |line|
              io.write(line)
            end
          end
        end
        Log.info "Wrote diff for #{change.path} -> #{diff_file}"
      end

    end
  end
end
