require 'test/unit'
require 'pebbles/mockit'

require 'damagecontrol/core/HostVerifyingHandler'

module DamageControl

  class HostVerifyingHandlerTest < Test::Unit::TestCase
    include MockIt

    def test_raises_unauthorized_error_on_disallowed_host
      verifier = new_mock
      verifier.__expect(:allowed?) {|host, ip| 
        assert_equal("host.evil.com", host)
        assert_equal("0.6.6.6", ip)
      }
      req = new_mock
      req.__setup(:peeraddr) { [nil, nil, "host.evil.com", "0.6.6.6"] }
      handler = HostVerifyingHandler.new(verifier)
      res = new_mock
      begin
        handler.call(req, res)
        fail
      rescue WEBrick::HTTPStatus::Unauthorized => e
        assert_match(/doesn.t allow/, e.message)
        assert_match(/host.evil.com/, e.message)
        assert_match(/0.6.6.6/, e.message)
      end
    end

  end

end
