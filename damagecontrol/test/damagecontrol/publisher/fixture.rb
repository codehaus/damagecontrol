require 'rscm/mockit'

module DamageControl
  module Publisher
    module Fixture
      # Creates a mock build that can be used in other publisher tests.
      def mock_build(successful)
        project = new_mock
        project.__setup(:name) {"TestProject"}
  
        changeset = new_mock
        changeset.__setup(:developer) {"Aslak"}
  
        build = new_mock
        build.__setup(:project) {project}
        build.__setup(:successful?) {successful}
        build.__setup(:changeset) {changeset}
        build.__setup(:status_message) {successful ? "Successful" : "Failed"}
        build
      end
    end
  end
end