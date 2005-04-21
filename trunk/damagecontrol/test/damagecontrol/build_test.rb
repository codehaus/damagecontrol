require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/build'

module DamageControl
  class BuildTest < Test::Unit::TestCase
    include MockIt
    
    def test_should_persist_exit_code_stderr_and_stdout
      temp = RSCM.new_temp_dir("test_should_persist_failure")
      execute_dir = "#{temp}/execute"
      changeset_dir = "#{temp}/changeset"

      p = new_mock

      changeset = new_mock
      changeset.__setup(:dir) {changeset_dir}
      changeset.__setup(:project) {p}

      t = Time.utc(1971,2,28,23,45,00)
      build = Build.new(changeset, t, "Testing")
      
      a_program = File.expand_path(File.dirname(__FILE__) + "/a_program.rb")
      build.execute("ruby #{a_program} 44", execute_dir, {'foo' => 'bar'})
      stderr = File.expand_path("#{changeset_dir}/builds/19710228234500/stderr.log")
      assert_equal("this\nis\nstderr\nbar", File.read(stderr))
      stdout = File.expand_path("#{changeset_dir}/builds/19710228234500/stdout.log")
      assert_equal("this\nis\nstdout\n44", File.read(stdout))
      assert_equal(44, build.exit_code)
    end

    def TODOtest_should_kill_long_running_build
      home = RSCM.new_temp_dir("killing")

      ENV["DAMAGECONTROL_HOME"] = home
      t = Time.utc(1971, 2, 28, 23, 45, 00)
      build = Build.new("mooky", "some_rev", t, "Test")
      a_program = File.expand_path(File.dirname(__FILE__) + "/a_slow_program.rb")
      t = Thread.new do
        build.execute("ruby #{a_program} 55", {'foo' => 'mooky'})
      end
      # make sure it's running
      sleep(2)
      build.kill
      stdout = "#{home}/projects/mooky/changesets/some_rev/builds/19710228234500/stdout.log"
      assert_equal("this\nis\nstdout\n44", File.read(stdout))
      assert_equal(nil, build.exit_code)
    end

  end
end