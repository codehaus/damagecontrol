require 'test/unit'
require 'damagecontrol/BuildBootstrapper'

module DamageControl

  class BuildBootstrapperTest < Test::Unit::TestCase
    def test_trigger_command
      assert_equal("nc localhost 4711 < damagecontrol-project_name.conf", 
        BuildBootstrapper.trigger_command("project_name", "damagecontrol-project_name.conf", "nc", "localhost", 4711))
    end
    
    def test_build_spec
      expected = <<-EOF
---
scm_spec: scm_spec
build_command_line: build_command_line
project_name: project_name
nag_email: nag_email
...
      EOF
      build_spec = BuildBootstrapper.build_spec("project_name", "scm_spec", "build_command_line", "nag_email")
      assert(build_spec.index("---"))
      assert(build_spec.index("project_name"))
      assert(build_spec.index("scm_spec"))
      assert(build_spec.index("build_command_line"))
      assert(build_spec.index("nag_email"))
      assert(build_spec.index("..."))
    end

    def test_create_build_from_yaml
      bs = BuildBootstrapper.new
      build = bs.create_build(yaml)
      assert_not_nil(build)
      assert_equal("scm_spec_value", build.scm_spec)
    end
    
    def yaml
      <<-EOF
      scm_spec: scm_spec_value
      EOF
    end
  end

end

