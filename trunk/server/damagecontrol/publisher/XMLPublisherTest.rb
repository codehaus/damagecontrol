require 'test/unit'
require 'pebbles/mockit'
require 'damagecontrol/core/BuildSerializer'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/publisher/XMLPublisher'

module DamageControl

  class XMLPublisherTest < Test::Unit::TestCase
    include MockIt
    include FileUtils
  
    def test_build_history_can_be_serialised_to_xml
      b = BuildSerializer.new.load("#{damagecontrol_home}/testdata/myproject/build/20041129234720", false)

      build_dir = new_temp_dir
      build_history_xml = "#{build_dir}/build_history.xml"

      build_history_repository = new_mock
      build_history_repository.__expect(:history) do |project_name, dc_creation_time, with_changesets|
        assert_equal("myproject", project_name)
        assert_equal(Time.utc(2004,11,29,23,47,20), dc_creation_time)
        assert(with_changesets)
        [b, b]
      end
      build_history_repository.__expect(:xml_history_file) do
        build_history_xml
      end

      xp = XMLPublisher.new(
        new_mock.__expect(:add_consumer),
        build_history_repository
      )
      
      xp.on_message(BuildCompleteEvent.new(b))
      assert_equal(File.open("#{damagecontrol_home}/testdata/myproject/build/build_history.xml").read.length, File.open(build_history_xml).read.length)
    end
    
  end
end
