require File.dirname(__FILE__) + '/../../../test_helper'

module DamageControl
  module Publisher
    class EmailTest < Test::Unit::TestCase

      def test_should_send_email_with_sendmail_on_publish
        if (ENV['DC_TEST_SENDMAIL_ENABLE'])
          email = Email.new
          email.to = ENV['DC_TEST_SENDMAIL_ENABLE']
          email.from = "dcontrol@codehaus.org"
          email.publish(@build_1)
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
          email = Email.new
          email.to = ENV['DC_TEST_SMTP_ENABLE']
          email.from = "dcontrol@codehaus.org"
          email.server = "localhost"
          email.publish(@build_1)
          # hard to assert success. verify manually.
        else
          puts "\n"
          puts "Skipping #{self.class.name} (#{__FILE__})"
          puts "If you have Internet access and an smtp server running you can enable this test by defining"
          puts "DC_TEST_SMTP_ENABLE=your@email in your shell"
          puts "\n"
        end
      end

      def test_should_send_email_with_gmail_on_publish
        if (ENV['GMAIL_PASSWORD'])
          email = Email.new
          email.to = ENV['GMAIL_ADDRESS']
          email.from = ENV['GMAIL_ADDRESS']
          email.password = ENV['GMAIL_PASSWORD']
          email.publish(@build_1)
          # hard to assert success. verify manually.
        else
          puts "\n"
          puts "Skipping #{self.class.name} (#{__FILE__})"
          puts "If you have Internet access and a GMail account you can enable this test by defining"
          puts "GMAIL_ADDRESS=your_gmail_address and GMAIL_PASSWORD=your_gmail_password in your shell"
          puts "\n"
        end
      end
    end
  end
end