require 'test/unit'
require 'rscm/mockit'
require 'rscm/changes'
require 'damagecontrol/publisher/base'
require 'damagecontrol/build'

module DamageControl
  module Publisher
    class EmailTest < Test::Unit::TestCase
      include MockIt
  
      def test_should_send_email_on_publish
        BuildMailer.template_root = File.expand_path(File.dirname(__FILE__))
        publisher = Email.new

        project = new_mock
        project.__expect(:name) { "mooky" }
        build = new_mock
        build.__expect(:project) { project }
        
        # not sure what to assert here...
        assert_equal("TMail::Mail", BuildMailer.create_email(build, publisher).class.name)
      end
    end
  end
end