require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class GrowlTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions

      def test_should_send_message_on_publish
        Growl.new.publish(@build_1)
        # hard to assert success. verify manually.
      end
    end
  end
end