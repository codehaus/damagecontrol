require 'test/unit'

class NoSuchSCMError < Exception
end

class SCMConnectionFactory
  def connect(scm_spec)
    raise NoSuchSCMError.new(scm_spec.inspect)
  end
end

class SCMConnectionFactoryTest < Test::Unit::TestCase
  
  def test_create_connection_factory_without_providers_raises_no_such_scm_error
    factory = SCMConnectionFactory.new
    assert_raises(NoSuchSCMError) do
      scm_spec = { "url" => "no_url" }
      factory.connect(scm_spec)
    end
  end
  
end