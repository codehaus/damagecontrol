# Makes monochrome pngs from all the colour ones
# http://rubyforge.org/forum/forum.php?thread_id=2092&forum_id=1618

require 'rubygems'
#require_gem 'rmagick'
require 'RMagick'

name = "garbage_empty"
img = Magick::ImageList.new("#{name}.png")
img = img.quantize(256, Magick::GRAYColorspace)
img.write("#{name}_monochrome.jpg")