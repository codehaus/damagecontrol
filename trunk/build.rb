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
    clean
    unit_test
#    integration_test
  end
  
  def existing_file(file)
    if !file.nil? && File.exists?(file) then file else nil end
  end

  def write_file(file, content)
    info("generating file #{file}")
    File.open(file, "w") {|io| io.puts(content) }
  end
  
  def build_number
    require 'server/damagecontrol/Version.rb'
    ENV["DAMAGECONTROL_BUILD_LABEL"] || params['build'] || params['build_number'] || DamageControl::BUILD
  end
  
  def release_name
    require 'server/damagecontrol/Version.rb'
    DamageControl::RELEASE
  end
  
  def version
    "#{release_name}-#{build_number}"
  end
  
  def target_dir
    params["target_dir"] || "target"
  end
  
  def dist_name
    "damagecontrol-#{version}"
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
    generate_version_info("#{dist_dir}/server/damagecontrol/Version.rb")
  end

  def generate_version_info(file)
    info("generating #{file}")
    require 'server/damagecontrol/Version.rb'
    write_file(file,
%{module DamageControl
  PRODUCT_NAME = "#{DamageControl::PRODUCT_NAME}"
  BUILD_NUMBER = "#{build_number}"
  RELEASE = "#{release_name}"
  VERSION = "\#{RELEASE}-\#{BUILD_NUMBER}"
  
  VERSION_TEXT = "\#{PRODUCT_NAME} version \#{VERSION}"
end
})
  end

  def windows?
    require 'rbconfig.rb'
    !Config::CONFIG["host"].index("mswin32").nil?
  end
  
  def jon_settings
    params['ruby_home'] = "c:\\projects\\damagecontrol\\ruby"
    params['cvs_executable'] = "c:\\bin\\cvs.exe"
    params['user'] = "tirsen"
    params['scp_executable'] = "pscp"
  end
  
  def aslak_windows_settings
    # This is where it lands after Make install
    params['ruby_home'] = "c:\\cygwin\\usr\\local"
    # This seems to be the most uptodate CVS version for windows
    params['cvs_executable'] = "\"C:\\Program Files\\TortoiseCVS\\cvs.exe\""
    params['user'] = "rinkrank"
    params['scp_executable'] = "pscp"
  end
  
  def installer_from_codehaus_build
    dist = "damagecontrol-#{version}.tar.gz"
    unless File.exists?("target/#{dist}")
      mkdir_p("target") unless File.exists?("target")
      with_working_dir("target") do
        system("wget http://dist.codehaus.org/damagecontrol/distributions/#{dist}")
      end
    end
    system("tar vzxf target/#{dist}")
    system("mv damagecontrol-#{version} dist")
    installer_nodeps
  end
  
  def installer_from_local_build
    dist_nodeps
    installer_nodeps
  end
  
  def missing_installer_variable(name, description, path)
    fail("Define the #{name} variable (with eg -D#{name}=#{path.inspect}) to point to a #{description}, it must be a Windows path and backslashes must be double")
  end
  
  def ruby_home
    params["ruby_home"] || missing_installer_variable("ruby_home", "ruby installation (a Cygwin build)", "c:\\ruby")
  end
  
  def cvs_executable
    params["cvs_executable"] || missing_installer_variable("cvs_executable", "CVS executable", "c:\\bin\\cvs.exe")
  end
  
  def makensis_executable
    existing_file(params["makensis_executable"]) ||
      existing_file("/cygdrive/c/Program Files/NSIS/makensis.exe") || 
      existing_file("C:\\Program Files\\NSIS\\makensis.exe") ||
      params["makensis_executable"] || 
      missing_installer_variable("makensis_executable", "NSIS executable (NSIS can be downloaded from http://nsis.sf.net)", "c:\\Program Files\\NSIS\\makensis.exe")
  end
  
  def installer_nodeps
    # call these to verify they are defined before starting to build
    ruby_home
    cvs_executable
    makensis_executable
    #svn_executable

    system("\"#{makensis_executable}\" /DVERSION=#{version} /DSVN_BIN=xx /DCVS_EXECUTABLE=#{cvs_executable} /DRUBY_HOME=#{ruby_home} installer/windows/nsis/DamageControl.nsi")
  end
  
  def archive
    dist
    archive_nodeps
  end
  
  def archive_nodeps
    info("creating archive target/#{dist_name}.tar.gz")
    begin
      mkdir_p("target/archive")
      system("cp -a #{dist_dir} target/archive")
      system("mv target/archive/dist target/archive/#{dist_name}")
      system("tar cf target/damagecontrol-#{version}.tar -C target/archive .")
      system("gzip target/damagecontrol-#{version}.tar")
    rescue
      fail("could not execute tar or gzip, if you're on windows install this: http://unxutils.sourceforge.net/")
    end
  end
  
  def clean
    if(windows?)
      rm_rf("target")
      rm_rf("dist")
    else
      system("rm -rf target")
      system("rm -rf dist")
    end
  end
  
  def user
    params["user"] || ENV["USERNAME"] || ENV["USER"]
  end
  
  def deploy_dest
    "#{user}@beaver.codehaus.org:/home/projects/damagecontrol/dist/distributions"
  end
  
  def scp_executable
    params["scp_executable"] || if windows? then "pscp" else "scp" end
  end
  
  def upload
    upload_nodeps
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
      info(client.proxy("control").shutdown_with_message_and_time(message, 10))
    rescue XMLRPC::FaultException => e
      fail(e.faultString)
    end
  end
  
  def self_upgrade
    unless windows?
      home = "/home/services/dcontrol"
      mkdir_p("#{home}/damagecontrol.new")
      system("cp -a #{dist_dir}/* #{home}/damagecontrol.new")
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
    archive_nodeps
    upload_nodeps
    self_upgrade
  end
  
  def upload_release_from_local
    clean
#    test
#    dist_nodeps
#    archive_nodeps
    installer_from_local_build
    upload_nodeps
  end
  
  def upload_release_from_codehaus
    clean
#    test
#    dist_nodeps
#    archive_nodeps
    installer_from_codehaus_build
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
