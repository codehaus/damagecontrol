require 'test/unit'
require 'damagecontrol/publisher/base'
require 'damagecontrol/publisher/fixture'

module DamageControl
  module Publisher
    class JabberTest < Test::Unit::TestCase
      include Fixture
  
      def test_should_send_message_on_publish
        Jabber.new.publish(mock_build(false))
      end
    end
  end
end