require 'test/unit'
require 'damagecontrol/BuildBootstrapper'

module DamageControl

  class BuildBootstrapperTest < Test::Unit::TestCase
    def test_create_build_from_yaml
      bs = BuildBootstrapper.new
      build = bs.create_build(yaml)
      assert_not_nil(build)
      assert_equal("scm_spec_value", build.scm_spec)
    end
    
    def yaml
%{
scm_spec: scm_spec_value
}      
    end
  end

end

