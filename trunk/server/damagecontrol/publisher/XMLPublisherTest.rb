require 'test/unit'
require 'pebbles/mockit'
require 'yaml'
require 'damagecontrol/publisher/XMLPublisher'

module DamageControl

  class XMLPublisherTest < Test::Unit::TestCase
    include MockIt
    include FileUtils
    include XmlSerialization
  
    def test_build_history_can_be_serialised_to_xml
      build_history = YAML::load(File.new("#{damagecontrol_home}/testdata/build_history.yaml"))
      out_path = "#{new_temp_dir}/build_history.xml"
      out = File.new(out_path, "w")
      build_history.to_xml.write(out, 2)
      out.close
      
      expected = "#{damagecontrol_home}/testdata/build_history.xml"
      assert_equal(File.read(expected), File.read(out_path))
    end
    
  end
end
