require 'test/unit'
require 'rscm'
require 'rscm/generic_scm_tests'

# TODO: This is bogus. doesn't work... Fix or delete this code.
module RSCM
  class P4Client
    include Test::Unit::Assertions

    def p4(cmd)
      assert_equal @expected, cmd
      @returnValue
    end

    def expect cmd, returnValue
      @expected = cmd
      @returnValue = returnValue
    end
  end

  class P4ClientTests < Test::Unit::TestCase
    def test_correctly_decodes_changes_specifiers
      client = P4Client.new "foo", nil, nil, nil, nil
      client.expect "changes //...@1200,2036/01/01:00:00:00", ""
      client.revisions("1200", Time.infinity) 
    end

    def test_should_accept_changespecs_for_from_and_to
      client = P4Client.new "foo", nil, nil, nil, nil
      client.expect "changes //...@1200,@1300", ""
      client.revisions("1200", "1300") 
    end

  end
end
