require 'pebbles/mockit'
require 'damagecontrol/core/BuildHistoryRepository'

module DamageControl

  class AbstractBuildHistoryTest < Test::Unit::TestCase
    
    include FileUtils
    include MockIt

    def test_dummy
    end
    
    def setup
      @apple1 = Build.new("apple", {"build_command_line" => "Apple1"})
      @apple1.status = Build::SUCCESSFUL
      @apple1.dc_start_time = Time.utc(2004,3,16,22,59,46)

      @pear1 = Build.new("pear", {"build_command_line" => "Pear1"})
      @pear1.dc_start_time = Time.utc(2004,3,16,22,59,47)
      
      @apple2 = Build.new("apple", {"build_command_line" => "Apple2"})
      @apple2.status = Build::FAILED
      @apple2.dc_start_time = Time.utc(2004,3,16,22,59,48)

      @bhp = BuildHistoryRepository.new(new_mock.__expect(:add_consumer))
      @bhp.register(@apple1)
      @bhp.register(@pear1)
      @bhp.register(@apple2)
    end

  end
end
