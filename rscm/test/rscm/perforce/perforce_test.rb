require 'test/unit'
require 'rscm/generic_scm_tests'
require 'rscm/perforce/perforce'

module RSCM
  class PerforceTest < Test::Unit::TestCase

    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      Perforce.new(repository_root_dir)
    end
  end
end