#!/usr/bin/env ruby

$VERBOSE = nil

class Project
  def initialize
    $damagecontrol_home = File::expand_path(".")
    
    $:<<'lib'
    $:<<'lib/rica'
    $:<<'src/ruby'
  end
  
  def run_test(test)
    Dir.chdir("#{$damagecontrol_home}/src/ruby")
    system("ruby -I#{$damagecontrol_home}/lib #{test}") || fail
    fail if ($? != 0)
  end

  def fail
    puts "BUILD FAILED: #{$?.to_s}"
    exit(1)
  end

  def unit_test
    run_test("AllTests.rb")
  end

  def integration_test
    run_test("End2EndTest.rb")
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
