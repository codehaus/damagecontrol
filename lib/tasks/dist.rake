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
  'bin/**/*',
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

  FileUtils.mv "#{DIST_DIR}/bin/eee_darwin", "dist"
  FileUtils.mv "#{DIST_DIR}/bin/rubyscript2exe.rb", "dist"
  FileUtils.mv "#{DIST_DIR}/bin/tar2rubyscript.rb", "dist"
end

GEMS = [
  "jabber4r",
  "rake",
  "RedCloth",
  "rscm",
  "ruby-growl",
  "meta_project",
  "mime-types",
  "sqlite-ruby"
]

# Although rubyscript2exe can automatically package gems, we prefer to do it
# our own way to limit the size of the final package. rubyscript2exe packages
# the entire gem in its entirety. we disable it and package only the lib part
# of each gem.

desc "Copy exploded gems to vendor"
task :copy_exploded_gems => [:copy_dist] do
  gems_dir = "dist/gems"
  FileUtils.rm_rf(gems_dir) if File.exist?(gems_dir)
  FileUtils.mkdir_p(gems_dir)

  Dir.chdir gems_dir do
    GEMS.each do |gem|
      sh "gem unpack #{gem}"
    end
  end

  FileUtils.mkdir_p(DIST_DIR) unless File.exist?(DIST_DIR)
  gemnames = Dir["#{gems_dir}/*"].collect{|f| File.basename(f)}
  gemnames.each do |gemname|
    gemdest = "#{DIST_DIR}/vendor/#{gemname}"
    FileUtils.mkdir_p gemdest
    FileUtils.cp_r("#{gems_dir}/#{gemname}/lib", gemdest)
  end
  
  # Write a file that will be loaded by dc_environment.rb
  gemlibs = "['" + gemnames.collect{|g| "vendor/#{g}/lib"}.join("','") + "']"
  gems_environment_script = <<-EOS
# This file was generated during DamageControl's build process
puts "Adding gems to loadpath"
GEMLIBS = #{gemlibs}
$:.unshift(GEMLIBS.collect{|p| RAILS_ROOT+"/"+p}.join(':'))
EOS
  File.open("#{DIST_DIR}/config/gems_environment.rb", "w") {|io| io.write gems_environment_script}
end

task :tar2rubyscript => [:copy_exploded_gems] do
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

desc "Publish the release files in Subversion repository."
task :tag_svn do
  # TODO: remove user name from SVN URL
  system("svn cp svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/trunk svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/tags/rel_#{PKG_VERSION.gsub(/\./,'-')} -m 'tagged release #{PKG_VERSION}'")
end
