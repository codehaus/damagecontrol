require 'test/unit'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class BaseTest < Test::Unit::TestCase
      def test_should_load_all_scm_classes
        expected = [
          Email,
          Growl,
          Irc
        ]
        assert_equal(
          expected.collect{|c| c.name},
          Base.classes.collect{|c| c.name}.sort)
      end
    end
  end
end
