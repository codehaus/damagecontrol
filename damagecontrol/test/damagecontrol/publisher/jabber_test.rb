require 'test/unit'
require 'rscm/mockit'
require 'rscm/changes'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class JabberTest < Test::Unit::TestCase
      include MockIt
  
      def test_should_send_message_on_publish
        project = new_mock
        project.__expect(:name) {"TestProject"}

        build = new_mock
        build.__expect(:project) {project}
        build.__expect(:status_message) {"Exploded"}

        Jabber.new.publish(build)
      end
    end
  end
end