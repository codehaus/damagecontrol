require 'test/unit'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'

module DamageControl

  class BuildTest < Test::Unit::TestCase

    def test_format_timestamp
      jons_birth_as_string = "19770614001001"
      jons_birth_as_time = Time.mktime(1977, 6, 14, 00, 10, 01)
      assert_equal(jons_birth_as_string, Build.format_timestamp(jons_birth_as_time))
      assert_equal(jons_birth_as_string, Build.format_timestamp(jons_birth_as_time.to_i))
      assert_equal(jons_birth_as_string, Build.format_timestamp(jons_birth_as_string))
    end
    
    def test_timestamp_to_i
      assert_equal(Time.utc("1977", "06", "14", "00", "10", "01").to_i,
        Build.timestamp_to_i("19770614001001"))
    end
    
  end

end
