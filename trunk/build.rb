#!/usr/bin/env ruby

$VERBOSE = nil

require 'fileutils'

class Object
  def system(*args)
    info(args.join(" "))
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
    files.delete_if {|f| f=~ /^\.#/}
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
  
  attr_accessor :targets
  attr_accessor :params

  def initialize
    $damagecontrol_home = File::expand_path(".")
    self.targets = []
    self.params = {}
  end
  
  def execute_ruby(test, safe_level=0)
    system("ruby -Iserver -T#{safe_level} #{test}")
  end

  def fail(message = $?.to_s)
    puts "BUILD FAILED: #{message}"
    exit!(1)
  end

  def run_test
    test = File.expand_path(params['test'] || "server/damagecontrol/test/AllTests.rb")
    execute_ruby(test)
  end

  def unit_test
    execute_ruby("server/damagecontrol/test/AllTests.rb")
  end

  def integration_test
    execute_ruby("server/damagecontrol/test/End2EndTest.rb")
  end
  
  def test
    unit_test
    integration_test
  end
  
  def makensis_executable
    existing_file(params["makensis_executable"]) ||
      existing_file("/cygdrive/c/Program Files/NSIS/makensis.exe") || 
      existing_file("C:\\Program Files\\NSIS\\makensis.exe") ||
      fail("NSIS needs to be installed, download from http://nsis.sf.net (you may need to add option -Dmakensis_executable=<path to makensis.exe>)")
  end
  
  def existing_file(file)
    if !file.nil? && File.exists?(file) then file else nil end
  end

  def write_file(file, content)
    info("generating file #{file}")
    File.open(file, "w") {|io| io.puts(content) }
  end
  
  def version
    load 'server/damagecontrol/Version.rb'
    DamageControl::VERSION
  end
  
  def target_dir
    params["target_dir"] || "target"
  end
  
  def dist_dir
    params["dist_dir"] || "#{target_dir}/dist"
  end
  
  def dist
    dist_nodeps
  end
  
  def dist_nodeps
    mkdir_p(dist_dir)
    cp("license.txt", dist_dir)
    cp("release-notes.txt", dist_dir)
    copy_dir("bin", "#{dist_dir}/bin")
    copy_dir("server", "#{dist_dir}/server")
    generate_startup_scripts
  end
  
  def generate_startup_scripts
    {
      "dctrigger" => "bin/dctrigger.rb",
      "server" => "bin/server.rb",
      "codehaus" => "bin/codehaus.rb",
      "ccbridge" => "bin/ccbridge.rb",
      "newproject" => "server/damagecontrol/tool/admin/newproject.rb",
      "requestbuild" => "server/damagecontrol/tool/admin/requestbuild.rb",
      "shutdownserver" => "server/damagecontrol/tool/admin/shutdownserver.rb"
    }.each{|s, t| generate_startup_script("#{dist_dir}/bin/#{s}", t) }
  end
  
  def generate_startup_script(script, target)
    win_target = target.gsub(/\//, "\\")
    write_file("#{script}.cmd", %{
      @echo off
      set DAMAGECONTROL_HOME=%~dp0..
      cd %DAMAGECONTROL_HOME%
      set RUBY_HOME="%DAMAGECONTROL_HOME%\\ruby"
      set PATH="%RUBY_HOME%\\bin";%PATH%
      echo %RUBY_HOME%\\bin\\ruby -I "%DAMAGECONTROL_HOME%\\server" "#{target}" %1 %2 %3 %4 %5 %6 %7 %8 %9
      %RUBY_HOME%\\bin\\ruby -I "%DAMAGECONTROL_HOME%\\server" "#{target}" %1 %2 %3 %4 %5 %6 %7 %8 %9
      pause
    }.gsub(/\n/, "\r\n"))
    write_file(script, %{
      \#!/bin/sh
      DAMAGECONTROL_HOME=`dirname $0`/..
      cd $DAMAGECONTROL_HOME
      export DAMAGECONTROL_HOME=`pwd`
      ruby -I"$DAMAGECONTROL_HOME/server" "#{target}" $*
    })
    system("chmod +x #{script}") unless windows?
  end
  
  def windows?
    require 'rbconfig.rb'
    !Config::CONFIG["host"].index("mswin32").nil?
  end
  
  def installer
    dist_nodeps
    installer_nodeps
  end
  
  def ruby_home
    params["ruby_home"] || ENV["RUBY_HOME"] || fail("Define the RUBY_HOME variable to point to your ruby installation")
  end
  
  def cvs_executable
    params["cvs_executable"] || "#{ENV['CVS_HOME']}/cvs.exe" || fail("Define the cvs_executable variable to point to your CVS binary (eg. -Dcvs_executable=c:\bin\cvs.exe)")
  end
  
  def svn_executable
    params["svn_executable"] || "#{ENV['SVN_HOME']}/svn.exe" || fail("Define the svn_executable variable to point to your Subversion client binary eg. -Dsvn_executable=c:\bin\svn.exe")
  end
  
  def installer_nodeps
    # call these to verify they are defined before starting to build
    ruby_home
    cvs_executable
    makensis_executable
    #svn_executable

    system("\"#{makensis_executable}\" /DVERSION=#{version} /DSVN_BIN= /DCVS_EXECUTABLE='#{cvs_executable}' /DRUBY_HOME='#{ruby_home}' installer/windows/nsis/DamageControl.nsi")
  end
  
  def archive
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
    rm_rf("target") if windows?
    system("rm -rf target") unless windows?
  end
  
  def username
    params["user"] || ENV["USERNAME"] || ENV["USER"]
  end
  
  def deploy_dest
    "#{username}@beaver.codehaus.org:/home/projects/damagecontrol/dist/distributions"
  end
  
  def scp_executable
    if windows? then "pscp" else "scp" end
  end
  
  def upload_nodeps
    upload_if_exists("target/DamageControl-#{version}.exe")
    upload_if_exists("target/damagecontrol-#{version}.tar.gz")
  end
  
  def upload_if_exists(file)
    system("#{scp_executable} #{file} #{deploy_dest}") if File.exists?(file)
  end
    
  def shutdown_server(message)
    begin
      require 'xmlrpc/client'
      client = ::XMLRPC::Client.new2("http://localhost:4712/private/xmlrpc")
      info(client.proxy("control").shutdown_with_message(message))
    rescue XMLRPC::FaultException => e
      fail(e.faultString)
    end
  end
  
  def self_upgrade
    unless windows?
      home = "/home/services/dcontrol"
      mkdir_p("#{home}/damagecontrol.new")
      system("cp -a target/dist/* #{home}/damagecontrol.new")
      system("rm -rf #{home}/damagecontrol.old")
      system("mv #{home}/damagecontrol #{home}/damagecontrol.old")
      system("mv #{home}/damagecontrol.new #{home}/damagecontrol")
    end
    shutdown_server("DamageControl is restarting (self upgrade)") rescue info("could not shutdown server")
    # daemontools should automatically start it again
  end
  
  def dc_build
    clean
    test
    dist_nodeps
    # this doesn't seem to work either!
    #archive_nodeps
    # doesn't seem to work yet for the dcontrol user :-(
    #upload_nodeps
    self_upgrade
  end
  
  def release
    clean
    test
    dist_nodeps
    archive_nodeps
    installer_nodeps
    upload_nodeps
  end
  
  def default
    test
  end

  def run_server
    info("starting server, point a web browser to: http://localhost:4712/private/dashboard")
    execute_ruby("server/damagecontrol/DamageControlServer.rb")
  end
  
  def parse_args(args)
    self.targets = args.dup.delete_if {|t| t =~/-.*/}
    validate_targets
    self.params = {}
    args.each do |t| 
      if(t =~/-D(.*)=(.*)/)
        params[$1] = $2.strip
      end
    end
  end
  
  def validate_targets
    targets.each do |t| 
      fail("no such target #{t}") unless self.respond_to?(t)
    end
  end
  
  def run(args)
    parse_args(args)
    begin
      if targets.nil? || targets == []
        default
      else
        targets.each {|target| instance_eval(target) }
      end
    rescue Exception => e
      #fail(e.message + "\n\t" + e.backtrace.join("\n\t"))
      fail(e.message)
    end
    puts "BUILD SUCCESSFUL"
  end
end

project = Project.new
project.run(ARGV)
