# This rake script packages DamageControl to a standalone executable.
# Executables can be made on any platform (TODO: verify this) that is supported by rubyscript2exe.
# The final executable embeds:
#
# * Ruby runtime (taken from your box)
# * All Ruby standard libraries that are needed by DamageControl (but not more)
# * All rubygems required by DamageControl (we use our own packaging scheme - see below)
# * The DamageControl appliaction itself
# * Ruby on Rails (from its SVN HEAD, currently under vendor/rails)
# * SQlite and other binaries used by DamageControl
# * A preconfigured SQLite database schema (TODO: make sure it's production and clean and support migrate)
#
# A SHELL_DIR variable is defined in script/damagecontrol. This is necessary in order for the packaged
# executable to figure out in what directory the app was started from. It is used to compute the data directory.
#
# The standalone executable can run both builder daemons and optionally serve the web
# interface via its embedded webserver (WEBrick).
#
# The executable should be good enough to be deployed under Apache or Lighttpd (with some tweaks),
# but this has not been thoroughly explored yet and is therefore undocumented. Until then it is
# probably easier to get DamageControl running under one of these web servers by running from 
# source (available via Subversion) and configure the webapp as any other RoR app. There is ample
# socumentation about this available from http://rubyonrails.com/
#
require 'meta_project'
require 'rake/contrib/sshpublisher'
require 'rake/contrib/rubyforgepublisher'
require 'damagecontrol/platform'

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'damagecontrol'
PKG_VERSION   = '0.6.0' + PKG_BUILD
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

# FileList excludes .svn files by default
PKG_FILES = FileList[
  'init.rb', # RubyScript2Exe bootstrapper
  '[A-Z]*',
  'Rakefile',
  'README.license',
  'app/**/*',
  "bin/#{DamageControl::Platform.family}/sqlite*",
  "bin/*",
  'components/**/*',
  'config/**/*',
  'db/production.db',
  'db/migrate/*',
  'doc/**/*',
  'lib/**/*',
  'log/**/*',
  'public/**/*',
  'script/**/*',
  'vendor/rails/actionmailer/lib/**/*',
  'vendor/rails/actionpack/lib/**/*',
  'vendor/rails/actionwebservice/lib/**/*',
  'vendor/rails/activerecord/lib/**/*',
  'vendor/rails/activesupport/lib/**/*',
  'vendor/rails/railties/lib/**/*'
]

DIST_DIR = "dist/#{PKG_FILE_NAME}"

task :verify_production_environment do
  raise "Build with RAILS_ENV=production to ensure procuction.db is migrated first!" unless RAILS_ENV == "production"
end

task :copy_dist => [:verify_production_environment, :migrate] do
  FileUtils.rm_rf("dist") if File.exist?("dist")
  FileUtils.mkdir_p(DIST_DIR)

  PKG_FILES.each do |file|
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
    # Disable gem bundling. We do it our own way (see :copy_exploded_gems)
    ruby "rubyscript2exe.rb #{PKG_FILE_NAME}.rb --dry-run"
  end
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