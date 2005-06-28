require 'rscm/revision'

module DamageControl
  module Visitor

    # Visitor that executes a build for each visited revision.
    # TODO: THIS CLASS IS NOT USED YET - FINISH IT. PASS A BLOCK TO CTOR.
    class BuildExecutor
      # Creates a new BuildExecutor that will build the project for
      # each visited revision. The +description+ will be persisted
      # with the build information to record what triggered the build.
      #
      def initialize(project, description)
        @project = project
      end

      def visit_revisions(revisions)
      end

      def visit_revision(revision)
        Log.info "Checking out revision #{revision.id} for #{@project.name}"
        project.checkout(revision.id)
        Log.info "Building #{@project.name}"
      end

      def visit_file(change)
      end

    end
  end
end
