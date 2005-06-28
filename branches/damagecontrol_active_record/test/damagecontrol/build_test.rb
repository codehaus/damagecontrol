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
      revision_dir = "#{temp}/revision"

      p = new_mock

      revision = new_mock
      revision.__setup(:dir) {revision_dir}
      revision.__setup(:project) {p}

      t = Time.utc(1971,2,28,23,45,00)
      a_program = File.expand_path(File.dirname(__FILE__) + "/a_program.rb")

# Program exit value | $?.to_i | $? >> 8
# 
# -256                       0         0
# -255                     256         1
#   -3                   64768       253
#   -2                   65024       254
#   -1                   65280       255
#    0                       0         0
#    1                     256         1
#    2                     512         2
#    3                     768         3
#  255                   65280       255
#  256                       0         0
# 

      # EXIT -1
      negative_build = Build.new(revision, t, "Testing")
      negative_build.execute("ruby #{a_program} -1", execute_dir, {'foo' => 'bar'})

      stderr = File.expand_path("#{revision_dir}/builds/19710228234500/stderr.log")
      assert_equal("this\nis\nstderr\nbar", File.read(stderr))
      stdout = File.expand_path("#{revision_dir}/builds/19710228234500/stdout.log")
      assert_equal("this\nis\nstdout\n-1", File.read(stdout))
      assert_equal(255, negative_build.exit_code)
      assert(!negative_build.successful?)

      # EXIT 0
      zero_build = Build.new(revision, t+1, "Testing")
      zero_build.execute("ruby #{a_program} 0", execute_dir, {'foo' => 'bar'})

      stderr = File.expand_path("#{revision_dir}/builds/19710228234501/stderr.log")
      assert_equal("this\nis\nstderr\nbar", File.read(stderr))
      stdout = File.expand_path("#{revision_dir}/builds/19710228234501/stdout.log")
      assert_equal("this\nis\nstdout\n0", File.read(stdout))
      assert_equal(0, zero_build.exit_code)
      assert(zero_build.successful?)

      # EXIT +1
      positive_build = Build.new(revision, t+2, "Testing")
      positive_build.execute("ruby #{a_program} 1", execute_dir, {'foo' => 'bar'})

      stderr = File.expand_path("#{revision_dir}/builds/19710228234502/stderr.log")
      assert_equal("this\nis\nstderr\nbar", File.read(stderr))
      stdout = File.expand_path("#{revision_dir}/builds/19710228234502/stdout.log")
      assert_equal("this\nis\nstdout\n1", File.read(stdout))
      assert_equal(1, positive_build.exit_code)
      assert(!positive_build.successful?)

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
      stdout = "#{home}/projects/mooky/revisions/some_rev/builds/19710228234500/stdout.log"
      assert_equal("this\nis\nstdout\n44", File.read(stdout))
      assert_equal(nil, build.exit_code)
    end

  end
end