require 'test/unit'
require 'fileutils'
require 'rscm'
require 'rscm/generic_scm_tests'

module RSCM
  class StarTeamTest < Test::Unit::TestCase
#    include GenericSCMTests

    def create_scm(repository_root_dir, path)
      StarTeam.new(ENV["STARTEAM_USER"], ENV["STARTEAM_PASS"], "192.168.254.21", 49201, "NGST Application", "NGST Application", "java")
    end

    def test_revisions
      from = Time.new - 2 * 3600 * 24
      to = Time.new - 1 * 3600 * 24
      puts "Getting revisions for #{from} - #{to}"
    
      revisions = create_scm(nil, nil).revisions(nil, from, to)
      assert_equal(1, revisions.length)
      assert_equal(Time.utc(2004, 11, 30, 04, 52, 24), revisions[0][0].time)
      assert_equal(Time.utc(2004, 11, 30, 04, 53, 23), revisions[0][1].time)
      assert_equal(Time.utc(2004, 11, 30, 04, 53, 23), revisions[0].time)
      assert_equal("rinkrank", revisions[0].developer)
      assert_equal("En to\ntre buksa \nned\n", revisions[0].message)
    end

    def test_checkout
      files = create_scm(nil, nil).checkout("target/starteam/checkout")
      assert_equal(3, files.length)
      assert_equal("eenie/meenie/minee/mo", files[0])
      assert_equal("catch/a/redneck/by", files[1])
      assert_equal("the/toe", files[2])
    end
  end
end
