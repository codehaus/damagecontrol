#!/usr/bin/env ruby


$VERBOSE = nil

class Project
  def initialize
    $damagecontrol_home = File::expand_path(".")
  end
  
  def run_test(test)
    Dir.chdir("#{$damagecontrol_home}/server")
    system("ruby -I. #{test}") || fail
    fail if ($? != 0)
  end

  def fail
    puts "BUILD FAILED: #{$?.to_s}"
    exit(1)
  end

  def unit_test
    run_test("damagecontrol/test/AllTests.rb")
  end

  def integration_test
    run_test("damagecontrol/test/End2EndTest.rb")
  end
  
  def all
    unit_test
    integration_test
  end
  
  def default
    all
  end
  
  def run(args)
    if args.nil? || args == []
      default
    else
      args.each {|target| instance_eval(target) }
    end
    puts "BUILD SUCCESSFUL"
  end
end

project = Project.new
project.run(ARGV)
