#!/bin/env ruby
#

require 'Gnuplot'

# Set up the arrays containing that will be plotted.
#
x = (1..100).to_a
y = x.collect { |i| i*i }

# Create the new plot object and set the global plot parameters
#
plot = Gnuplot::Plot.new()
plot.title "Line plot using ArrayData" 
plot.xlabel "x" 
plot.ylabel "y" 

# Create an ArrayData object to plot the data and set the parameters for the
# plot item.  Then plot it.
#
ds = y.gpds("with"=>"lines", "title" => "Data", "xgrid"=>x)

plot.draw ds
