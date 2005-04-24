require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/builder'
require 'damagecontrol/build_queue'

module DamageControl
  class BuilderTest < Test::Unit::TestCase
    include MockIt
  
    def test_builds_request_from_queue
      queue = new_mock
      builder = Builder.new(queue)

      req = new_mock
      queue.__expect(:pop) do |balder|
        assert_same(builder, balder)
        req.__expect(:revision) do
          revision = new_mock
          revision.__expect(:build!) do |reasons|
            assert_equal(["just", "because"], reasons)
          end
        end
        req.__expect(:reasons) do
          ["just", "because"]
        end
      end
      queue.__expect(:delete) do |request|
        assert_same(req, request)
      end
      
      builder.build_next
    end
  end
end