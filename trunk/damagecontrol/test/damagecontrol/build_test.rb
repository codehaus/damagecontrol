require 'test/unit'
require 'rscm/mockit'
require 'rscm/tempdir'
require 'damagecontrol/build'

module DamageControl
  class BuildTest < Test::Unit::TestCase
    include MockIt
    
    def test_should_write_stderr_and_stdout_to_files_on_execute
      home = RSCM.new_temp_dir("successful_execute")

      ENV["DAMAGECONTROL_HOME"] = home
      t = Time.utc(1971, 2, 28, 23, 45, 00)
      build = Build.new("mooky", "some_rev", t)
      a_program = File.expand_path(File.dirname(__FILE__) + "/a_program.rb")
      build.execute("ruby #{a_program} 0")
      stderr = "#{home}/mooky/changesets/some_rev/builds/19710228234500/stderr.log"
      assert_equal("this\nis\nstderr", File.read(stderr))
      stdout = "#{home}/mooky/changesets/some_rev/builds/19710228234500/stdout.log"
      assert_equal("this\nis\nstdout\n0", File.read(stdout))
      assert_equal(0, build.exit_code)
    end

    def test_should_persist_failure
      home = RSCM.new_temp_dir("failed_execute")

      ENV["DAMAGECONTROL_HOME"] = home
      t = Time.utc(1971, 2, 28, 23, 45, 00)
      build = Build.new("mooky", "some_rev", t)
      a_program = File.expand_path(File.dirname(__FILE__) + "/a_program.rb")
      build.execute("ruby #{a_program} 44")
      stdout = "#{home}/mooky/changesets/some_rev/builds/19710228234500/stdout.log"
      assert_equal("this\nis\nstdout\n44", File.read(stdout))
      assert_equal(44, build.exit_code)
    end

    def Xtest_should_kill_long_running_build
      home = RSCM.new_temp_dir("killing")

      ENV["DAMAGECONTROL_HOME"] = home
      t = Time.utc(1971, 2, 28, 23, 45, 00)
      build = Build.new("mooky", "some_rev", t)
      a_program = File.expand_path(File.dirname(__FILE__) + "/a_slow_program.rb")
      t = Thread.new do
        build.execute("ruby #{a_program} 55")
      end
      # make sure it's running
      sleep(2)
      build.kill
      stdout = "#{home}/mooky/changesets/some_rev/builds/19710228234500/stdout.log"
      assert_equal("this\nis\nstdout\n44", File.read(stdout))
      assert_equal(nil, build.exit_code)
    end

  end
end