require 'Gnuplot'
require 'matrix'


m = Matrix[[1,2,3],[4,5,6],[7,8,9]]

p = Gnuplot::Splot.new
p.surface

p.draw ( m.gpds("linestyle" => "lines") )

