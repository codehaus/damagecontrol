#!/bin/env ruby
#

require 'Gnuplot'

# Draw a new plot that is sin(x) over the range 0, 2*pi. Remember that since
# the strings are being passed directly to gnuplot, we can take advantage of
# its built in variables.
#
plot = Gnuplot::Plot.new

plot.title "Sin plot using StringFunc"
plot.ylabel "sin(x)"

plot.draw "sin(x)".gpds( "xrange" => "[0:2*pi]", "yrange" => "[-1:1]" )
 
