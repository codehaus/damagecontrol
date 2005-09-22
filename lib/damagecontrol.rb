require_gem 'rscm'
require_gem 'jabber4r'
require_gem 'rake'
require_gem 'RedCloth'
require_gem 'ruby-growl'
require_gem 'meta_project'
require_gem 'mime-types'

require 'rscm'
require 'meta_project'
require 'damagecontrol/platform'
require 'damagecontrol/dom'
require 'damagecontrol/rscm_ext/base'
require 'damagecontrol/publisher/base'
require 'damagecontrol/meta_project/project_ext'
require 'damagecontrol/meta_project/scm_web_ext'
require 'damagecontrol/meta_project/tracker_ext'
require 'damagecontrol/meta_project/build_tool'
require 'damagecontrol/importer/meta_project'
require 'damagecontrol/scm_poller'
require 'damagecontrol/build_daemon'
require 'damagecontrol/core_ext/pathname'
require 'damagecontrol/core_ext/class'

require_gem 'sqlite-ruby'
require 'damagecontrol/sqlite/retry'


exit if defined?(REQUIRE2LIB) # rubyscript2exe pqackaging mode

