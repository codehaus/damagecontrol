require 'damagecontrol/core/CheckoutManager'

require 'test/unit'
require 'pebbles/mockit'

module DamageControl

  class CheckoutManagerTest < Test::Unit::TestCase
  
    include MockIt
    
    # No unit tests yet, since this was factored out from BuildExecutor and SCMPoller, but
    # it is tested in the integration test.
    def test_no_unit_tests
    end

  end

end