require File.dirname(__FILE__) + '/../test_helper'
require 'build_result_mailer'

class BuildResultMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"
  fixtures :builds, :projects, :revisions, :revision_files

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end
  
  def test_should_render_email_with_changed_files
    @expected.subject = "project_1: Fixed build (commit by aslak)"

    mail = BuildResultMailer.create_build_result("nah@not.real", "dcontrol@codehaus.org", @build_1)
    assert_equal(@expected.subject, mail.subject)
    assert_match(/three\/blind\/mice\.rb/, mail.body)
    #assert_equal @expected.encoded, mail.encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/build_result_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
