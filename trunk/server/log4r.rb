# :include: log4r/rdoc/log4r
#
# == Other Info
#
# Author::      Leon Torres
# Version::     $Id: log4r.rb,v 1.2 2004/06/17 16:48:21 tirsen Exp $

require "log4r/outputter/fileoutputter"
require "log4r/outputter/consoleoutputters"
require "log4r/outputter/staticoutputter"
require "log4r/outputter/rollingfileoutputter"
require "log4r/formatter/patternformatter"
require "log4r/loggerfactory"

module Log4r
  Log4rVersion = [1, 0, 1].join '.'
end
