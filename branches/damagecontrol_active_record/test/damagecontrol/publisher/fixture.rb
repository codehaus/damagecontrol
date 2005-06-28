require 'rscm/mockit'
require 'rscm/revision_fixture'

module DamageControl
  module Publisher
    module Fixture
      include MockIt
      include RSCM::RevisionFixture

      # Creates a mock build that can be used in other publisher tests.
      def mock_build(successful)
        project = new_mock
        project.__setup(:name) {"TestProject"}
  
        setup_changes
        revisions = RSCM::Revisions.new
        revisions.add(@change1)
        revisions.add(@change2)
        revisions.add(@change3)
        revisions.add(@change4)
        revisions.add(@change5)
        revisions.add(@change6)
        revisions.add(@change7)
        revisions.each{|revision| revision.project = project}
  
        build = new_mock
        build.__setup(:project) {project}
        build.__setup(:successful?) {successful}
        build.__setup(:revision) {revisions[3]}
        build.__setup(:status_message) {successful ? "Successful" : "Failed"}
        build
      end
    end
  end
end