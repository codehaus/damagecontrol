require 'test/unit'
require 'fileutils'
require 'rscm/generic_scm_tests'
require 'rscm/monotone/monotone'

module RSCM
  class MonotoneTest < Test::Unit::TestCase
    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      mt = Monotone.new("#{repository_root_dir}/MT.db",
          "com.example.testproject",
          "tester@test.net")
    end
  end
end
