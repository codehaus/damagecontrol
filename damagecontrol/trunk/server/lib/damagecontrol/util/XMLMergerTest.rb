require 'test/unit'
require 'stringio'

require 'damagecontrol/util/XMLMerger'

module DamageControl
  class XMLMergerTest < Test::Unit::TestCase
  
    def setup
      @result = ""
      @merger = XMLMerger.new("damagecontrol", StringIO.new(@result))
    end
  
    def test_merge_one_xml_file
      xml1 = <<EOF
<?xml version='1.0'?>
<stuff/>
EOF
      expected_result = <<EOF
<?xml version='1.0'?>
<damagecontrol>
<stuff/>
</damagecontrol>
EOF
      @merger.merge(StringIO.new(xml1))
      @merger.close
      assert_equal(expected_result.strip, @result.strip)
    end
    
    def test_merge_one_xml_file_with_content_on_same_line
      xml1 = <<EOF
<?xml version='1.0'?><stuffonsameline/>
EOF
      expected_result = <<EOF
<?xml version='1.0'?>
<damagecontrol>
<stuffonsameline/>
</damagecontrol>
EOF
      @merger.merge(StringIO.new(xml1))
      @merger.close
      assert_equal(expected_result.strip, @result.strip)
    end

    def test_merge_several_log_files
      xml1 = <<EOF
<?xml version='1.0'?>
<stuff/>
EOF
      xml2 = <<EOF
<?xml version='1.0'?><stuff2/>
EOF
      xml3 = <<EOF
<?xml version='1.0'?><morestuff></morestuff>
EOF
      xml4 = <<EOF
<?xml version='1.0'?><morestuff2>
</morestuff2>
EOF
      expected_result = <<EOF
<?xml version='1.0'?>
<damagecontrol>
<stuff/>
<stuff2/>
<morestuff></morestuff>
<morestuff2>
</morestuff2>
</damagecontrol>
EOF
      @result = ""
      @merger = XMLMerger.open("damagecontrol", StringIO.new(@result)) do |m|
        m.merge(StringIO.new(xml1))
        m.merge(StringIO.new(xml2))
        m.merge(StringIO.new(xml3))
        m.merge(StringIO.new(xml4))
      end
      assert_equal(expected_result.strip, @result.strip)
    end
  end
end