require 'rscm/mockit'
require 'rscm/changes_fixture'

module DamageControl
  module Publisher
    module Fixture
      include MockIt
      include RSCM::ChangesFixture

      # Creates a mock build that can be used in other publisher tests.
      def mock_build(successful)
        project = new_mock
        project.__setup(:name) {"TestProject"}
  
        setup_changes
        changesets = RSCM::ChangeSets.new
        changesets.add(@change1)
        changesets.add(@change2)
        changesets.add(@change3)
        changesets.add(@change4)
        changesets.add(@change5)
        changesets.add(@change6)
        changesets.add(@change7)
  
        build = new_mock
        build.__setup(:project) {project}
        build.__setup(:successful?) {successful}
        build.__setup(:changeset) {changesets[3]}
        build.__setup(:status_message) {successful ? "Successful" : "Failed"}
        build
      end
    end
  end
end