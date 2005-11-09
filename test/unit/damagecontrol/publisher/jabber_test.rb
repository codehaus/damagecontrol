require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class JabberTest < Test::Unit::TestCase
      fixtures :builds, :projects, :revisions

      def test_should_send_message_on_publish
        build = builds(:build_1)
        if (ENV['DC_TEST_JABBER_ENABLE'])
          jabber = Jabber.new
          jabber.id_resource = "damagecontrol@jabber.codehaus.org/damagecontrol"
          jabber.friends = "aslak@jabber.codehaus.org"
          jabber.publish(build)
          # hard to assert success. verify manually.
        else
          # todo: ping somewhere to figure out automatically
          puts "\n"
          puts "Skipping #{self.class.name} (#{__FILE__})"
          puts "If you have Internet access you can enable this test by defining"
          puts "DC_TEST_JABBER_ENABLE=true in your shell"
          puts "\n"
        end
      end
    end
  end
end