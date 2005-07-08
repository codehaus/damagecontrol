require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    module Email
      class EmailTest < Test::Unit::TestCase
        fixtures :builds, :projects, :revisions, :revision_files
  
        def test_should_send_email_with_sendmail_on_publish
          if (ENV['DC_TEST_SENDMAIL_ENABLE'])
            sendmail = Sendmail.new
            sendmail.to = ENV['DC_TEST_SENDMAIL_ENABLE']
            sendmail.from = "dcontrol@codehaus.org"
            sendmail.publish(@build_1)
            # hard to assert success. verify manually.
          else
            puts "\n"
            puts "Skipping #{self.class.name} (#{__FILE__})"
            puts "If you have Internet access and sendmail running you can enable this test by defining"
            puts "DC_TEST_SENDMAIL_ENABLE=your@email in your shell"
            puts "\n"
          end
        end
  
        def test_should_send_email_with_smtp_on_publish
          if (ENV['DC_TEST_SMTP_ENABLE'])
            smtp = Smtp.new
            smtp.to = ENV['DC_TEST_SMTP_ENABLE']
            smtp.from = "dcontrol@codehaus.org"
            smtp.publish(@build_1)
            # hard to assert success. verify manually.
          else
            puts "\n"
            puts "Skipping #{self.class.name} (#{__FILE__})"
            puts "If you have Internet access and an smtp server running you can enable this test by defining"
            puts "DC_TEST_SMTP_ENABLE=your@email in your shell"
            puts "\n"
          end
        end
      end
    end
  end
end