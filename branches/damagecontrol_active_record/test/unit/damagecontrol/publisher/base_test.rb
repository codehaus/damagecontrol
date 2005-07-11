require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class BaseTest < Test::Unit::TestCase
      def test_should_load_all_publisher_classes
        expected = [
          #AmbientOrb,
          ArtifactArchiver,
          #BuildDuration,
          Email::Sendmail,
          Email::Smtp,
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
          Base.classes.collect{|c| c.name})
      end
    end
  end
end
