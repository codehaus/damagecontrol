require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class BaseTest < Test::Unit::TestCase

      def test_should_load_all_publisher_classes
        expected = [
          AmbientOrb,
          ArtifactArchiver,
          #BuildDuration,
          Email,
          #Execute,
          Growl,
          #Irc,
          Jabber,
          Sound,
          #X10Cm11A,
          X10Cm17A
          #Yahoo
        ]
        assert_equal(
          expected,
          Base.classes.collect{|c| c.new.class})
      end

      class StubPublisher < Base
        attr_reader :published
        
        def publish(build)

          @published = true
        end
      end

      def test_should_publish_if_successful_enabled
        fixed_build = builds(:build_1)
        
        pub = StubPublisher.new
        pub.publish_maybe(fixed_build)
        assert(pub.published.nil?)

        pub.enabling_states = [Build::Fixed.new]
        pub.publish_maybe(fixed_build)
        assert(pub.published)
      end
    end
  end
end
