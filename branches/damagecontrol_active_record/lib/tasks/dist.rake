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
  'db/**/*',
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

task :copy_dist do
  dist_dir = "dist/#{PKG_FILE_NAME}"
  FileUtils.rm_rf(dist_dir) if File.exist?(dist_dir)
  FileUtils.mkdir_p(dist_dir)

  PKG_FILES.each do |file|
    dest = File.join(dist_dir, file)
    FileUtils.mkdir_p(File.dirname(dest)) unless File.exist?(File.dirname(dest))
    cp_r(file, dest) unless File.directory?(file) # don't copy dirs, as they will bring along .svn files
  end

  FileUtils.mv "#{dist_dir}/bin/eee_darwin", "dist"
  FileUtils.mv "#{dist_dir}/bin/rubyscript2exe.rb", "dist"
  FileUtils.mv "#{dist_dir}/bin/tar2rubyscript.rb", "dist"
end

task :tar2rubyscript => [:copy_dist] do
  Dir.chdir "dist" do
    ruby "tar2rubyscript.rb #{PKG_FILE_NAME}"
  end
end

desc "Create a self-contained executable"
task :rubyscript2exe => [:tar2rubyscript] do
  puts
  puts "When the server comes up, kill it with CTRL-C"
  puts
  # TODO: kill it automatically so it can be built by dc itself
  Dir.chdir "dist" do
    ruby "rubyscript2exe.rb #{PKG_FILE_NAME}.rb"
  end
end

desc "Publish the release files in Subversion repository."
task :tag_svn do
  # TODO: remove user name from SVN URL
  system("svn cp svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/trunk svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/tags/rel_#{PKG_VERSION.gsub(/\./,'-')} -m 'tagged release #{PKG_VERSION}'")
end