require 'test/unit'
require 'damagecontrol/core/Build'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class BuildTest < Test::Unit::TestCase

    def test_format_timestamp
      jons_birth_as_string = "19770615001001"
      jons_birth_as_time = Time.utc(1977, 6, 15, 00, 10, 01)
      assert_equal(jons_birth_as_string, Build.format_timestamp(jons_birth_as_time))
      assert_equal(jons_birth_as_string, Build.format_timestamp(jons_birth_as_time.to_i))
      assert_equal(jons_birth_as_string, Build.format_timestamp(jons_birth_as_string))
    end
    
    def test_timestamp_to_i
      assert_equal(Time.utc("1977", "06", "15", "00", "10", "01").to_i,
        Build.timestamp_to_i("19770615001001"))
    end

    def test_setting_timestamp_from_integer_makes_timestamp_as_i_return_same_integer
      build = Build.new
      build.timestamp = 0
      assert_equal(0, build.timestamp_as_i)
    end

    def test_applying_format_timestamp_and_timestamp_to_i_returns_to_same_number
      assert_equal(0, Build.timestamp_to_i(Build.format_timestamp(0)))
    end
    
  end

end
