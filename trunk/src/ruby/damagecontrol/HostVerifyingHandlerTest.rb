require 'test/unit'
require 'mockit'

require 'damagecontrol/HostVerifyingHandler'

module DamageControl

  class HostVerifyingHandlerTest < Test::Unit::TestCase

    def test_raises_unauthorized_error_on_disallowed_host
      verifier = MockIt::Mock.new
      verifier.__expect(:allowed?) {|host, ip| 
        assert_equal("host.evil.com", host)
        assert_equal("0.6.6.6", ip)
      }
      req = MockIt::Mock.new
      req.__setup(:peeraddr) { [nil, nil, "host.evil.com", "0.6.6.6"] }
      handler = HostVerifyingHandler.new(verifier)
      res = MockIt::Mock.new
      begin
        handler.call(req, res)
        fail
      rescue WEBrick::HTTPStatus::Unauthorized => e
        assert_match(/doesn.t allow/, e.message)
        assert_match(/host.evil.com/, e.message)
        assert_match(/0.6.6.6/, e.message)
      end
      verifier.__verify
      req.__verify
      res.__verify
    end

  end

end
