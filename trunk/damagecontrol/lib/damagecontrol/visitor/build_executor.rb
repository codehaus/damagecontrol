require 'rscm/changes'

module DamageControl
  module Visitor

    # Visitor that executes a build for each visited changeset.
    # TODO: THIS CLASS IS NOT USED YET - FINISH IT. PASS A BLOCK TO CTOR.
    class BuildExecutor
      # Creates a new BuildExecutor that will build the project for
      # each visited changeset. The +description+ will be persisted
      # with the build information to record what triggered the build.
      #
      def initialize(project, description)
        @project = project
      end

      def visit_changesets(changesets)
      end

      def visit_changeset(changeset)
        Log.info "Checking out changeset #{changeset.id} for #{@project.name}"
        project.checkout(changeset.id)
        Log.info "Building #{@project.name}"
      end

      def visit_change(change)
      end

    end
  end
end
