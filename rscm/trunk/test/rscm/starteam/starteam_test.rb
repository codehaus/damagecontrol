require 'test/unit'
require 'fileutils'
require 'rscm/generic_scm_tests'
require 'rscm/starteam/starteam'

module RSCM
  class MookyTest < Test::Unit::TestCase
#    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      StarTeam.new
    end
    
    def test_yaml
      changesets = create_scm(nil, nil).changesets(nil, Time.new, Time.new)
      assert_equal(1, changesets.length)
      assert_equal(Time.utc(2004, 11, 30, 04, 52, 24), changesets[0][0].time)
      assert_equal(Time.utc(2004, 11, 30, 04, 53, 23), changesets[0][1].time)
      assert_equal(Time.utc(2004, 11, 30, 04, 53, 23), changesets[0].time)
      assert_equal("rinkrank", changesets[0].developer)
      assert_equal("En to\ntre buksa \nned\n", changesets[0].message)
    end
  end
end
