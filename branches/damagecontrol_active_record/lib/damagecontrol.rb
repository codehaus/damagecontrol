# This file explicitly requires a lot of stuff.
# This must be done here so that rubyscript2exe can
# discover what it needs to bundle up!
require 'rubygems'
require 'set'
require 'rss/maker'
require 'rss/parser'
require 'optparse'
require 'webrick'
require 'logger'
require 'fileutils'
require 'rscm'
require 'meta_project'
require 'ferret'
if(RSCM::Platform.family != "mswin32")
  require 'fcgi'
end

require 'damagecontrol/ferret_config'
require 'damagecontrol/rscm_ext/base'
require 'damagecontrol/publisher/base'
require 'damagecontrol/meta_project/project_ext'
require 'damagecontrol/meta_project/scm_web_ext'
require 'damagecontrol/meta_project/tracker_ext'
require 'damagecontrol/meta_project/build_tool'
require 'damagecontrol/importer/meta_project'
require 'damagecontrol/process/base'
require 'damagecontrol/process/scm_poller'
require 'damagecontrol/process/builder'
require 'damagecontrol/zipper'
require 'damagecontrol/core_ext/class'
require 'damagecontrol/core_ext/hash'
require 'damagecontrol/core_ext/pathname'

# Add binaries to path
ENV['PATH'] = File.expand_path(File.dirname(__FILE__) + "/../bin/#{RSCM::Platform.family}") + File::PATH_SEPARATOR + ENV['PATH']
exit if defined?(REQUIRE2LIB) # rubyscript2exe packaging mode
