require 'test/unit'
require 'damagecontrol/publisher/base'
require 'damagecontrol/publisher/fixture'

module DamageControl
  module Publisher
    class EmailTest < Test::Unit::TestCase
      include Fixture
  
      def test_should_send_email_on_publish
        BuildMailer.template_root = File.expand_path(File.dirname(__FILE__) + "/../../../app/views")
        publisher = Email.new
        tmail = BuildMailer.create_email(mock_build(true), publisher)
        body = tmail.body_port.ropen.read
        assert(body.index("Successful build (by aslak)"))
        assert(body.index("path/seven"))
        to = ENV["DC_EMAIL_TEST"]
        if(to)
          publisher.to = to
          puts "Sending mail to #{to} (for real)"
          BuildMailer.deliver_email(mock_build(true), publisher)
        end
      end
    end
  end
end