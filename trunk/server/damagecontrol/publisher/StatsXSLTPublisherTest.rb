require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/publisher/StatsXSLTPublisher'
require 'damagecontrol/util/FileUtils'
require 'rexml/document'

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
      expected = File.open("#{damagecontrol_home}/testdata/myproject/stats/build_duration2.svg").read
      actual = File.open("#{stats_dir}/build_duration.svg").read
      assert_xml_equal(expected, actual)
    end
    
    def assert_xml_equal(expected_xml, actual_xml)
      pref = {:ignore_whitespace_nodes=>:all}

      e = ""
      expected = REXML::Document.new(expected_xml, pref)
      expected.write(e, 2)

      a = ""
      actual = REXML::Document.new(actual_xml, pref)
      actual.write(a, 2)

      if(e.length != a.length)
        puts "Expected:"
        puts e
        puts
        puts "Actual:"
        puts a
        fail("XML not equal")
      end
    end
    
  end
end
