require 'rubygems'
require_gem 'log4r'

Log = Log4r::Logger.new("rscm")
Log.level = ENV["LOG4R_LEVEL"] ? ENV["LOG4R_LEVEL"].to_i : 0
Log.add Log4r::Outputter.stderr
