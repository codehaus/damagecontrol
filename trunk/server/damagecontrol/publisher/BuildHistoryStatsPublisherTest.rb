require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/BuildSerializer'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/publisher/BuildHistoryStatsPublisher'

module DamageControl

  class BuildHistoryStatsPublisherTest < Test::Unit::TestCase
    include MockIt
    include FileUtils
  
    def test_build_history_can_be_serialised_to_xml
      b = BuildSerializer.new.load("#{damagecontrol_home}/testdata/myproject/build/20041129234720", false)

      project_dir = new_temp_dir
      build_history_xml = "#{project_dir}/build/build_history.xml"
      build_history_stats_xml = "#{project_dir}/stats/build_history_stats.xml"

      build_history_repository = new_mock
      build_history_repository.__expect(:history) do |project_name, with_changesets|
        assert_equal("myproject", project_name)
        assert(!with_changesets)
        [b, b]
      end
      build_history_repository.__setup(:project_dir) do
        project_dir
      end

      xp = BuildHistoryStatsPublisher.new(
        new_mock.__expect(:add_consumer),
        build_history_repository
      )
      
      xp.on_message(BuildCompleteEvent.new(b))
      assert_equal(File.open("#{damagecontrol_home}/testdata/myproject/build/build_history.xml").read.length, File.open(build_history_xml).read.length)
      assert_equal(File.open("#{damagecontrol_home}/testdata/myproject/stats/build_history_stats.xml").read.length, File.open(build_history_stats_xml).read.length)
    end
    
  end
end
