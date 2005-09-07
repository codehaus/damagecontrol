require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'
require 'rake/contrib/rubyforgepublisher'
require 'meta_project'

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'damagecontrol'
PKG_VERSION   = '0.6.0' + PKG_BUILD
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

PKG_FILES = FileList[
  '[A-Z]*',
  'Rakefile',
  'README.license',
  'app/**/*', 
  'bin/**/*', 
  'components/**/*', 
  'config/**/*', 
  'db/migrate/**/*', 
  'doc/**/*', 
  'lib/**/*', 
  'log/**/*', 
  'public/**/*', 
  'script/**/*', 
  'test/**/*',
  'vendor/**/*'
]

desc "Delete files generated during test"
task :clean_target_unless_production do
  FileUtils.rm_rf 'target' unless RAILS_ENV == 'production'
end

task :clone_structure_to_test => [:clean_target_unless_production]
task :migrate => [:clean_target_unless_production]
task :db_structure_dump => [:migrate, :environment]

# Support Tasks ------------------------------------------------------

def egrep(pattern)
  Dir['**/*.rb'].each do |fn|
    count = 0
    open(fn) do |f|
      while line = f.gets
        count += 1
        if line =~ pattern
          puts "#{fn}:#{count}:#{line}"
        end
      end
    end
  end
end

desc "Look for TODO and FIXME comments in the code"
task :todo do
  egrep /#.*(FIXME|TODO|TBD)/
end

desc "Make greyscale (sepia) images"
task :greyscale do
  require 'RMagick'

  colour_pngs = FileList.new('public/images/**/*.png')
  colour_pngs.exclude('public/images/**/*_grey.png')
  colour_pngs.exclude('public/images/raw/**/*')
  colour_pngs.to_a.each do |png|
    img = Magick::ImageList.new(png)
    # img = img.sepiatone
    img = img.quantize(256, Magick::GRAYColorspace)
    img = img.colorize(0.30, 0.30, 0.30, '#cc9933')

    grey_png = png.gsub(/\.png/, "_grey.png")
    puts "writing greyscale image #{grey_png}"
    img.write(grey_png)
  end
end

spec = Gem::Specification.new do |s|

  #### Basic information.

  s.name = 'damagecontrol'
  s.version = PKG_VERSION
  s.summary = "DamageControl"
  s.description = <<-EOF
    DamageControl - a Continuous Integration server.
  EOF

  #### Dependencies and requirements.

  s.add_dependency('rscm', '>= 0.3.2')
  s.add_dependency('rails', '>= 0.13.1.1962')
#  s.add_dependency('log4r', '1.0.5')
  s.add_dependency('jabber4r', '0.8.0')
  s.add_dependency('RedCloth', '3.0.3')
  s.add_dependency('ruby-growl', '1.0.0')
  s.add_dependency('rmagick', '1.9.0')
  s.add_dependency('sparklines', '0.2.4')

  s.files = PKG_FILES.to_a

  s.require_path = 'lib'
  s.autorequire = 'damagecontrol'

  s.bindir = "bin"                               # Use these for applications.
  s.executables = ["damagecontrol-daemon", "damagecontrol-webrick"]
  s.default_executable = "damagecontrol-daemon"

  #### Documentation and testing.

  #s.has_rdoc = true
  #s.extra_rdoc_files = rd.rdoc_files.reject { |fn| fn =~ /\.rb$/ }.to_a
  #rd.options.each do |op|
  #  s.rdoc_options << op
  #end

  #### Author and project details.

  s.author = "Aslak Hellesoy and Jon Tirsen"
  s.email = "dev@damagecontrol.codehaus.org"
  s.homepage = "http://damagecontrol.codehaus.org/"
#    s.rubyforge_project = "rscm"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc "Publish the release files in Subversion repository."
task :tag_svn do
  # TODO: remove user name from SVN URL
  system("svn cp svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/trunk svn+ssh://rinkrank@beaver.codehaus.org/home/projects/damagecontrol/scm/tags/rel_#{PKG_VERSION.gsub(/\./,'-')} -m 'tagged release #{PKG_VERSION}'")
end