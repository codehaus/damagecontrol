require 'test/unit'
require 'rscm/mockit'
require 'rscm/changes'
require 'damagecontrol/publisher/base'

module DamageControl
  module Publisher
    class EmailTest < Test::Unit::TestCase
      include MockIt
  
      def test_should_send_email_on_publish
        project = new_mock
        project.__setup(:name) { "mooky" }

        publisher = Email.new
                

        build = new_mock
        build.__setup(:project) { project }
        build.__setup(:status_message) { "Kaboom" }
        
        BuildMailer.template_root = File.expand_path(File.dirname(__FILE__) + "/../../../app/views")
        # not sure what to assert here...
        tmail = BuildMailer.create_email(build, publisher)
        puts tmail.body_port.ropen.read
      end
    end
  end
end