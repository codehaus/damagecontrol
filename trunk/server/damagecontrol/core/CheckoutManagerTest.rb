require 'damagecontrol/core/CheckoutManager'
require 'damagecontrol/core/Build'

require 'test/unit'
require 'pebbles/mockit'

module DamageControl

  class CheckoutManagerTest < Test::Unit::TestCase
  
    include MockIt
    
    def test_checks_out_on_do_checkout_event_and_posts_checked_out_event
      time = Time.new

      scm = new_mock.__expect(:checkout) {time}

      hub = new_mock.__expect(:add_consumer) {|s| s.is_a?(CheckoutManager)}.
                     __expect(:put) {|e| e.is_a?(CheckedOutEvent)}
      project_directories = new_mock.__expect(:checkout_dir) {"somewhere"}
      project_config_repository = new_mock
      project_config_repository.__expect(:create_scm) {scm}
      project_config_repository.__expect(:project_config) {{"last_commit_time" => time}}
      project_config_repository.__expect(:modify_project_config)
      
      cm = CheckoutManager.new(
        hub,
        project_directories,
        project_config_repository  
      )
      
      cm.on_message(DoCheckoutEvent.new("myproject", true))
    end

  end

end