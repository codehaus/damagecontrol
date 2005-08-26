desc "Delete files generated during test"
task :clean_target_unless_production do
  FileUtils.rm_rf 'target' unless RAILS_ENV == 'production'
end

task :clone_structure_to_test => [:clean_target_unless_production]
task :migrate => [:clean_target_unless_production]

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
