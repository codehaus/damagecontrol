require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/publisher/StatsXSLTPublisher'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class StatsXSLTPublisherTest < Test::Unit::TestCase
    include FileUtils
    include MockIt

    def test_transforms_with_xslt_on_xml_produced_event
      stats_dir = new_temp_dir
      File.copy("#{damagecontrol_home}/testdata/myproject/stats/build_history_stats.xml", stats_dir)
    
      p = StatsXSLTPublisher.new(
        new_mock.__expect(:add_consumer),
        {
          "#{damagecontrol_home}/server/damagecontrol/publisher/stats_to_svg.xsl" => "build_duration.svg"
        }
      )
      p.put(StatProducedEvent.new("myproject", "#{stats_dir}/build_history_stats.xml"))
      expected = File.open("#{damagecontrol_home}/testdata/myproject/stats/build_duration.svg").read
      actual = File.open("#{stats_dir}/build_duration.svg").read
      assert_equal(expected, actual)
    end
    
  end
end
