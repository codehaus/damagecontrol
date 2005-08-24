desc "Delete files generated during test"
task :clean_target do
  FileUtils.rm_rf 'target'
end
task :clone_structure_to_test => [:clean_target]

desc "Recreate the dev database from schema.sql"
task :recreate_schema => :environment do
  abcs = ActiveRecord::Base.configurations
  case abcs["development"]["adapter"]
    when "sqlite", "sqlite3"
      db = "#{abcs['development']['dbfile']}"
      File.delete(db) if File.exist?(db)
      `#{abcs[RAILS_ENV]["adapter"]} #{db} < db/schema_sqlite.sql`
    else 
      raise "Unknown database adapter '#{abcs["test"]["adapter"]}'"
  end
end

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

desc "Create self-updating test project"
task :create_test_project => [:environment] do
  # TODO: make a copy before we import, to avoid .svn files...
  require 'rscm'
  require 'build'
  path = File.expand_path('target/test_project_repo')
  FileUtils.rm_rf(path) if File.exist?(path)
  scm = RSCM::Subversion.new(RSCM::PathConverter.filepath_to_nativeurl(path + "/trunk/foo"), "trunk/foo")
  # yaml the scm. test_project's build script needs it to commit changes to itself.
  File.open("test_project/scm.yaml", "w") do |io|
    io.write(scm.to_yaml)
  end

  scm.create_central  
  scm.import_central('test_project', "importing")

  if(!Project.find_by_name("test_project"))
    aa = DamageControl::Publisher::ArtifactArchiver.new
    aa.files = {"pkg/*.gem" => "gems"}
    aa.enabling_states = [Build::Successful.new, Build::Fixed.new]

    growl = DamageControl::Publisher::Growl.new
    growl.enabling_states = [Build::Broken.new, Build::Fixed.new]

    sound = DamageControl::Publisher::Sound.new
    sound.enabling_states = [Build::Broken.new, Build::Fixed.new]

    jira = Tracker::Jira::JiraProject.new
    scm_web = ScmWeb::DamageControl.new    

    test_project = Project.create(
      :name => "test_project",
      :home_page => "http://hieraki.lavalamp.ca/",
      :start_time => 2.weeks.ago.utc, 
      :relative_build_path => "", 
      :build_command => "rake", 
      :scm => scm,
      :tracker => jira,
      :scm_web => scm_web,
      :publishers => [aa, growl, sound]
    )
  end
end