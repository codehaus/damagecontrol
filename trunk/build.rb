#!/usr/bin/env ruby

$VERBOSE = nil

require 'fileutils'

class Object
  def system(*args)
    result = super(*args)
    raise "#{args} failed" if ($? != 0)
  end
end

module Logging
  def info(msg)
    puts msg
  end
end

module Files
  include Logging
  include FileUtils

  def all_files_recursively(dir)
    if File.directory?(dir)
      entries = Dir["#{dir}/*"]
      entries.collect {|entry| all_files_recursively(entry)}.flatten
    else
      dir
    end
  end
  
  def all_files(src)
    src = File.expand_path(src)
    src_length = src.size + 1
    files = all_files_recursively(src).collect {|f| File.expand_path(f)[src_length..-1]}
    files.delete_if {|f| f =~ /CVS\//}
  end
  
  def copy_dir(src, dest)
    files = all_files(src)
    info("copying #{files.size} files to #{dest}")
    files.each do |file|
      file_dest = "#{dest}/#{File.dirname(file)}"
      mkdir_p(file_dest)
      cp("#{src}/#{file}", file_dest)
    end
  end
  
  def with_working_dir(dir)
    prev_dir = Dir.pwd
    begin
      Dir.chdir(dir)
      yield
    ensure
      Dir.chdir(prev_dir)
    end
  end
end

class Project

  include Files

  def initialize
    $damagecontrol_home = File::expand_path(".")
  end
  
  def execute_ruby(test, safe_level=0)
    with_working_dir("#{$damagecontrol_home}/server") do
      system("ruby -I. -T#{safe_level} #{test}")
    end
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
  
  def test
    unit_test
    integration_test
  end
  
  def makensis_exe
    "C:\\Program Files\\NSIS\\makensis.exe"
  end

  def write_file(file, content)
    info("generating file #{file}")
    File.open(file, "w") {|io| io.puts(content) }
  end
  
  def version
    load 'server/damagecontrol/Version.rb'
    DamageControl::VERSION
  end
  
  def dist
    mkdir_p("target/dist")
    cp("license.txt", "target/dist")
    copy_dir("bin", "target/dist/bin")
    copy_dir("server", "target/dist/server")
    generate_startup_scripts
  end
  
  def generate_startup_scripts
    {
      "dctrigger" => "bin/dctrigger.rb",
      "server" => "bin/server.rb",
      "newproject" => "server/damagecontrol/tool/admin/newproject.rb",
      "requestbuild" => "server/damagecontrol/tool/admin/requestbuild.rb",
      "shutdownserver" => "server/damagecontrol/tool/admin/shutdownserver.rb"
    }.each{|s, t| generate_startup_script("target/dist/bin/#{s}", t) }
  end
  
  def generate_startup_script(script, target)
    win_target = target.gsub(/\//, "\\")
    write_file("#{script}.cmd", %{
      @echo off
      set DAMAGECONTROL_HOME=%~dp0..
      cd %DAMAGECONTROL_HOME%
      set RUBY_HOME="%DAMAGECONTROL_HOME%\\ruby"
      set PATH="%RUBY_HOME%\\bin";%PATH%
      ruby -I"%DAMAGECONTROL_HOME%\\server" "%DAMAGECONTROL_HOME%\\#{win_target}"
    })
    write_file(script, %{
      \#!/bin/sh
      export DAMAGECONTROL_HOME=%~dp0..
      cd $DAMAGECONTROL_HOME
      export RUBY_HOME="$DAMAGECONTROL_HOME/ruby"
      export PATH="$RUBY_HOME/bin":$PATH
      ruby -I"$DAMAGECONTROL_HOME/server" "$DAMAGECONTROL_HOME/#{target}"
    })
    system("chmod +x #{script}") unless windows?
  end
  
  def windows?
    require 'rbconfig.rb'
    !Config::CONFIG["host"].index("win").nil?
  end
  
  def installer
    test
    dist
    installer_nodeps
  end
  
  def installer_nodeps
    fail("Define the RUBY_HOME variable to point to your ruby installation") if !ENV["RUBY_HOME"]
    fail("Define the CVS_HOME variable to point to your CVS installation (can be TortoiseCVS)") if !ENV["CVS_HOME"]
    fail("NSIS needs to be installed, download from http://nsis.sf.net (or not installed to default place: #{makensis_exe})") if !File.exists?(makensis_exe)
    system("#{makensis_exe} /DVERSION=#{version} /DRUBY_HOME=#{ENV["RUBY_HOME"]} installer/windows/nsis/DamageControl.nsi")
  end
  
  def archive
    test
    dist
    archive_nodeps
  end
  
  def archive_nodeps
    info("creating archive target/damagecontrol-#{version}.tar.gz")
    begin
      system("tar cf target/damagecontrol-#{version}.tar -C target/dist .")
      system("gzip target/damagecontrol-#{version}.tar")
    rescue
      fail("could not execute tar or gzip, if you're on windows install this: http://unxutils.sourceforge.net/")
    end
  end
  
  def clean
    rm_rf("target")
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
  
  def upload
    dist
    installer_nodeps
    archive_nodeps
    upload_nodeps
  end
  
  def upload_nodeps
    system("#{scp_exe} target/DamageControl-#{version}.exe #{deploy_dest}")
    system("#{scp_exe} target/damagecontrol-#{version}.tar.gz #{deploy_dest}")
  end
  
  def release
    clean
    test
    upload
  end
  
  def all
    unit_test
    integration_test
  end
  
  def default
    test
  end

  def run_server
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
      fail(e.message + e.backtrace.join("\n"))
    end
    puts "BUILD SUCCESSFUL"
  end
end

project = Project.new
project.run(ARGV)
