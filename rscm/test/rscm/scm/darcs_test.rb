require 'test/unit'
require 'fileutils'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class DarcsTest < Test::Unit::TestCase
    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      Darcs.new(repository_root_dir)
    end
  end
end
