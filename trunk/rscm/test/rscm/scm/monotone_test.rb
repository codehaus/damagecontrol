require 'test/unit'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class MonotoneTest < Test::Unit::TestCase
    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      mt = Monotone.new(
        "com.example.testproject",
        "tester@test.net",
        "tester@test.net",
        File.dirname(__FILE__) + "/keys",
        "localhost",
        "#{repository_root_dir}/central_repo"
      )
    end
  end
end
