require 'test/unit'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class PerforceTest < Test::Unit::TestCase

    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      Perforce.new(repository_root_dir)
    end
  end
end