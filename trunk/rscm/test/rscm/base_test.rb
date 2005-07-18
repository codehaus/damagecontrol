require 'test/unit'
require 'rscm'

module RSCM
  class BaseTest < Test::Unit::TestCase
    def test_should_load_all_scm_classes
      expected_scms_classes = [
        Cvs,
#        Darcs,
        Monotone,
#        Mooky,
        Perforce,
#        StarTeam,
        Subversion
      ]
      assert_equal(
        expected_scms_classes.collect{|c| c.name},
        Base.classes.collect{|c| c.name}.sort)
    end
  end
end
