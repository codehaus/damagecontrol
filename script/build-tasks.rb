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
      `#{abcs[RAILS_ENV]["adapter"]} #{db} < db/schema.sql`
    else 
      raise "Unknown database adapter '#{abcs["test"]["adapter"]}'"
  end
end

desc "Run the DamageControl Webapp"
task :webrick do
  ruby "script/server"
end

desc "Run the DamageControl Daemon"
task :daemon do
  ruby "script/daemon"
end

desc "Create sample projects"
task :create_sample_projects do
  ruby "script/create_sample_projects"
end

desc "Recreate database, create sample projects and run daemon"
task :daemon_from_scratch => [:recreate_schema, :create_sample_projects, :daemon]

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

desc "Make greyscale images"
task :greyscale do
  require 'RMagick'

  colour_pngs = FileList.new('public/images/**/*.png')
  colour_pngs.exclude('public/images/**/*_grey.png')
  colour_pngs.exclude('public/images/raw/**/*')
  colour_pngs.to_a.each do |png|
    img = Magick::ImageList.new(png)
    img = img.quantize(256, Magick::GRAYColorspace)

    grey_png = png.gsub(/\.png/, "_grey.png")
    puts "writing greyscale image #{grey_png}"
    img.write(grey_png)
  end
end

desc "Make square pngs from raw images"
task :square_from_raw do
  require 'RMagick'

  raws = FileList.new('public/images/raw/**/*')
  raws.to_a.each do |raw|
    img = Magick::ImageList.new(raw)
    puts img[0]
    img.resize!(48, 48)
#    img = img.quantize(256, Magick::GRAYColorspace)

    suffix = File.extname(raw)
    basename = File.basename(raw, suffix)
    colour_png = "public/images/#{basename}.png"
    puts "writing square colour image #{colour_png}"
    img.write(colour_png)
  end
end