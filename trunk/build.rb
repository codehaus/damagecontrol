#!/usr/bin/env ruby

$VERBOSE = nil

class Object
  def system(*args)
    result = super(*args)
    raise "#{args} failed" if ($? != 0)
  end
end

class Project
  def initialize
    $damagecontrol_home = File::expand_path(".")
  end
  
  def execute_ruby(test, safe_level=0)
    Dir.chdir("#{$damagecontrol_home}/server")
    system("ruby -I. -T#{safe_level} #{test}")
  end

  def fail(message = $?.to_s)
    puts "BUILD FAILED: #{message}"
    exit!(1)
  end

  def unit_test
    execute_ruby("damagecontrol/test/AllTests.rb")
  end

  def integration_test
    execute_ruby("damagecontrol/test/End2EndTest.rb")
  end
  
  def makensis_exe
    "C:\\Program Files\\NSIS\\makensis.exe"
  end

  def write_file(file, content)
    File.open(file, "w") {|io| io.puts(content) }
  end
  
  def version
    load 'server/damagecontrol/Version.rb'
    DamageControl::VERSION
  end
  
  def installer
    fail("put a ruby distribution in #{File.expand_path('ruby')}") if !File.exists?("ruby")
    fail("NSIS needs to be installed, download from http://nsis.sf.net (or not installed to default place: #{makensis_exe})") if !File.exists?(makensis_exe)
    
    system("#{makensis_exe} /DVERSION=#{version} installer/windows/nsis/DamageControl.nsi")
  end
  
  def username
    "tirsen"
  end
  
  def deploy_dest
    "#{username}@beaver.codehaus.org:/home/projects/damagecontrol/dist/distributions"
  end
  
  def scp_exe
    "pscp"
  end
  
  def deploy
    installer
    deploy_nodeps
  end
  
  def deploy_nodeps
    system("#{scp_exe} target/DamageControl-#{version}.exe #{deploy_dest}")
  end
  
  def all
    unit_test
    integration_test
  end
  
  def default
    all
  end

  def server
    execute_ruby("damagecontrol/DamageControlServer.rb")
  end
  
  def run(args)
    begin
      if args.nil? || args == []
        default
      else
        args.each {|target| instance_eval(target) }
      end
    rescue Exception => e
      fail(e.message)
    end
    puts "BUILD SUCCESSFUL"
  end
end

project = Project.new
project.run(ARGV)
