require 'test/unit'
require 'rscm/mockit'
require 'rscm/changes'
require 'damagecontrol/publisher/base'
require 'damagecontrol/publisher/fixture'

module DamageControl
  module Publisher
    class GrowlTest < Test::Unit::TestCase
      include MockIt
      include Fixture
  
      def test_should_send_message_on_publish
        Growl.new.publish(mock_build(false))
      end
    end
  end
end