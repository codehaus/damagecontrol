# This rake script packages DamageControl to standard zip/tgz archives and also a standalone executable.
# Executables can be made on any platform that is supported by rubyscript2exe.
# The final executable embeds:
#
# * Ruby runtime (taken from your box)
# * All Ruby standard libraries that are needed by DamageControl (but not more)
# * All rubygems required by DamageControl
# * The DamageControl appliaction itself
# * Ruby on Rails (from its SVN HEAD, currently under vendor/rails)
# * SQlite and other binaries used by DamageControl
# * A preconfigured SQLite database schema
#
# A SHELL_DIR variable is defined in script/damagecontrol. This is necessary in order for the packaged
# executable to figure out in what directory the app was started from. It is used to compute the data directory.
#
# The standalone executable can run both builder daemons and optionally serve the web
# interface via its embedded webserver (WEBrick).
#
# The exe is using webrick. In the future we may embed lighttpd/scgi (better performance). This may
# require cygwin on windows since lighttpd doesn't run on win32 (AFAIK)
# 
# 
require 'meta_project'
require 'rake/packagetask'
require 'rake/contrib/sshpublisher'
require 'rake/contrib/rubyforgepublisher'
require 'damagecontrol/platform'

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'damagecontrol'
PKG_VERSION   = '0.6.0' + PKG_BUILD
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

# Files to package. See :rubyscript2exe and PackageTask for modifications
PKG_FILES = FileList[
  "init.rb", # RubyScript2Exe bootstrapper
  "[A-Z]*",
  "Rakefile",
  "README.license",
  "app/**/*",
  "components/**/*",
  "config/**/*",
  "db/production.db",
  "db/migrate/*",
#  "doc/**/*",
  "lib/**/*",
  "log/**/*",
  "public/**/*",
  "script/**/*",
  "vendor/rails/actionmailer/lib/**/*",
  "vendor/rails/actionpack/lib/**/*",
  "vendor/rails/actionwebservice/lib/**/*",
  "vendor/rails/activerecord/lib/**/*",
  "vendor/rails/activesupport/lib/**/*",
  "vendor/rails/railties/lib/**/*"
]

# Extra stuff needed for 'classic' packaging
PACKAGE_INCLUDES = [
  "bin/**/*"
]

DIST_DIR = "dist/#{PKG_FILE_NAME}"

task :verify_production_environment do
  raise "Build with RAILS_ENV=production to ensure procuction.db is migrated first!" unless RAILS_ENV == "production"
end

task :prepare_dist => [:verify_production_environment, :migrate, :clear_logs]
task :package => [:prepare_dist]

task :copy_dist => [:prepare_dist] do
  FileUtils.rm_rf("dist") if File.exist?("dist")
  FileUtils.mkdir_p(DIST_DIR)

  files = PKG_FILES.dup
  files.include(
    "bin/#{DamageControl::Platform.family}/sqlite3*",
    "bin/eee*",
    "bin/*rubyscript*"
  )

  files.each do |file|
    dest = File.join(DIST_DIR, file)
    FileUtils.mkdir_p(File.dirname(dest)) unless File.exist?(File.dirname(dest))
    FileUtils.cp_r(file, dest) unless File.directory?(file) # don't copy dirs, as they will bring along .svn files
  end

  FileUtils.mv "#{DIST_DIR}/bin/eee_linux", "dist"
  FileUtils.mv "#{DIST_DIR}/bin/eee_darwin", "dist"
  FileUtils.mv "#{DIST_DIR}/bin/eeew.exe", "dist"
  FileUtils.mv "#{DIST_DIR}/bin/rubyscript2exe.rb", "dist"
  FileUtils.mv "#{DIST_DIR}/bin/tar2rubyscript.rb", "dist"
end

task :tar2rubyscript => [:copy_dist] do
  Dir.chdir "dist" do
    ruby "tar2rubyscript.rb #{PKG_FILE_NAME}"
  end
end

desc "Create a self-contained executable"
task :rubyscript2exe => [:tar2rubyscript] do
  Dir.chdir "dist" do
    ruby "rubyscript2exe.rb #{PKG_FILE_NAME}.rb --dry-run"
  end
end

desc "Create a distro"
Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
  files = PKG_FILES.dup
  files.include("bin/**/*")
  files.exclude(
    "bin/eee*",
    "bin/*rubyscript*"
  )

  p.need_tar = true
  p.package_files = files
end

desc "Tag the release."
task :tag_svn do
  # TODO: remove user name from SVN URL
  system("svn cp svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/trunk svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/tags/rel_#{PKG_VERSION.gsub(/\./,'-')} -m 'tagged release #{PKG_VERSION}'")
end

desc "Upload to aslakhellesoy.com"
task :upload do
  `pscp dist\\#{PKG_FILE_NAME}.exe aslak.hellesoy@chilco.textdrive.com:/users/home/aslak.hellesoy/web/public/damagecontrol/downloads`
end