$:<<'../../lib'

require 'damagecontrol/Hub'
require 'damagecontrol/BuildHistoryRepository'

module DamageControl

  class AbstractBuildHistoryTest < Test::Unit::TestCase
    
    def test_dummy
    end
    
    def setup
      @apple1 = Build.new("apple", {"build_command_line" => "Apple1"})
      @apple1.status = Build::SUCCESSFUL
      @apple1.timestamp = "20040316225946"

      @pear1 = Build.new("pear", {"build_command_line" => "Pear1"})
      @pear1.timestamp = "20040316225947"
      
      @apple2 = Build.new("apple", {"build_command_line" => "Apple2"})
      @apple2.status = Build::FAILED
      @apple2.timestamp = "20040316225948"

      @bhp = BuildHistoryRepository.new(Hub.new)
      @bhp.register(@apple1)
      @bhp.register(@pear1)
      @bhp.register(@apple2)
    end

  end
end
