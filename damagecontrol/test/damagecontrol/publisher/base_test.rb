require 'test/unit'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class BaseTest < Test::Unit::TestCase
      def test_should_load_all_scm_classes
        expected = [
          #AmbientOrb,
          #BuildDuration,
          Email,
          #Execute,
          Growl,
          #Irc,
          Jabber,
          #X10Cm11A,
          #X10Cm17A,
          #Yahoo
        ]
        assert_equal(
          expected.collect{|c| c.name},
          Base.classes.collect{|c| c.name}.sort)
      end
    end
  end
end
