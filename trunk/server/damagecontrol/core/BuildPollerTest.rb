require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/util/HubTestHelper'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'

module DamageControl
  class BuildPollerTest < Test::Unit::TestCase
    include HubTestHelper
    
    def test_requests_build_only_for_projects_with_poll_interval_for_each_poll_intervalth_tick
      create_hub
      mock_pcr = MockIt::Mock.new
      poller = BuildPoller.new(hub, mock_pcr)

      tick_count = 0
      (1..100).each do |n|
        mock_pcr.__expect(:project_names) { ["doesnt_like_polling", "likes_polling_every_3_secs"] }
        mock_pcr.__expect(:project_config) { |project_name| {} }
        mock_pcr.__expect(:project_config) { |project_name| {"poll_interval" => 3} }

        if(n%3 != 0)
          poller.force_tick
          assert_equal(tick_count, messages_from_hub.length)
        else
          mock_pcr.__expect(:create_build) do |project_name, time| 
            assert_equal("likes_polling_every_3_secs", project_name)
            Build.new(project_name)
          end
          poller.force_tick
          assert_equal(tick_count + 1, messages_from_hub.length)
          assert_got_message(BuildRequestEvent)
          tick_count += 1
        end
      end
      assert_equals(100, tick_count)
      assert_equals(10, messages_from_hub.length)

      mock_pcr.__verify
    end

  end
end
