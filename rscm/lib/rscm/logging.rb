require 'rubygems'
require_gem 'log4r'

Log = Log4r::Logger.new("rscm")
Log.add Log4r::Outputter.stderr
