require 'test/unit'
require 'fileutils'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class MookyTest < Test::Unit::TestCase
    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      Mooky.new
    end
  end
end
