require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class BaseTest < Test::Unit::TestCase
      def test_should_load_all_publisher_classes
        expected = [
          #AmbientOrb,
          ArtifactArchiver,
          MockPublisher,
          #BuildDuration,
          Email::Sendmail,
          Email::Smtp,
          #Execute,
          Growl,
          #Irc,
          Jabber,
          Sound
          #X10Cm11A,
          #X10Cm17A,
          #Yahoo
        ]
        assert_equal(
          expected.collect{|c| c.name},
          Base.classes.collect{|c| c.name})
      end

      class MockPublisher < Base
        register self
        attr_reader :published
        
        def publish(build)
          @published = true
        end
      end

      def test_should_publish_if_successful_enabled
        build = Build.create(:reason => Build::SCM_POLLED, :state => Build::Fixed.new)
        
        pub = MockPublisher.new
        pub.publish_maybe(build)
        assert(pub.published.nil?)

        pub.enabling_states = [Build::Fixed.new]
        pub.publish_maybe(build)
        assert(pub.published)
      end
    end
  end
end
