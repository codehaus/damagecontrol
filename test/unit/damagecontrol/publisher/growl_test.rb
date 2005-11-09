require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class GrowlTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions

      def test_should_send_message_on_publish
        Growl.new.publish(builds(:build_1))
        # hard to assert success. verify visually.
      end
    end
  end
end