require 'rscm/changes'
require 'damagecontrol/directories'

module DamageControl
  module Visitor

    # Visitor that persists unified diffs to disk.
    #
    class DiffPersister
      # Creates a new Differ that will persist diffs to file.
      #
      def initialize(scm, project_name)
        @scm, @project_name = scm, project_name
      end

      def visit_changesets(changesets)
      end

      def visit_changeset(changeset)
        @changeset = changeset
puts "Writing diffs for #{@project_name} changeset #{changeset.id}"
      end

      def visit_change(change)
        diff_file = Directories.diff_file(@project_name, @changeset, change)
puts " Writing diff for #{change.path} -> #{diff_file}"
        checkout_dir = Directories.checkout_dir(@project_name)
        @scm.diff(checkout_dir, change) do |diff_io|
          FileUtils.mkdir_p(File.dirname(diff_file))
          File.open(diff_file, "w") do |io|
            diff_io.each_line do |line|
              io.write(line)
            end
          end
        end
      end

    end
  end
end
