require 'test/unit'
require 'damagecontrol/Build'
require 'damagecontrol/FileUtils'

module DamageControl

  class BuildTest < Test::Unit::TestCase

    def test_format_timestamp
      assert_equal("19770614001001",
        Build.format_timestamp(Time.mktime(1977, 6, 14, 00, 10, 01)))
    end
    
  end

end
