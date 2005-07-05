require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    module Email
      class EmailTest < Test::Unit::TestCase
        fixtures :builds, :projects, :revisions, :revision_files
  
        def test_should_send_email_with_sendmail_on_publish
          #verify_email(Sendmail.new)
        end
  
        def test_should_send_email_with_smtp_on_publish
          smtp = Smtp.new
          smtp.port = 2005
          verify_email(smtp)
        end

      private

        def verify_email(publisher)
          tmail = BuildMailer.create_email(@build_1, publisher)
          body = tmail.body_port.ropen.read
          assert_match(/project_1: Successful/, body)
          assert_match(/Commit by aslak/, body)
          assert_match(/three\/blind\/mice\.rb/, body)

          if (ENV['DC_TEST_EMAIL_ENABLE'])
            publisher.to = ENV['DC_TEST_EMAIL_ENABLE']
            BuildMailer.deliver_email(@build_1, publisher)
            # hard to assert success. verify manually.
          else
            # todo: ping somewhere to figure out automatically
            puts "\n"
            puts "Skipping #{self.class.name} (#{__FILE__})"
            puts "If you have Internet access you can enable this test by defining"
            puts "DC_TEST_EMAIL_ENABLE=your@email in your shell"
            puts "\n"
          end
        end
      end
    end
  end
end