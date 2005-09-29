# This file explicitly requires a lot of stuff.
# This must be done here so that rubyscript2exe can
# discover what it needs to bundle up!
require 'damagecontrol/platform'

require_gem 'rscm'
require_gem 'jabber4r'
require_gem 'rake'
require_gem 'RedCloth'
require_gem 'ruby-growl'
require_gem 'meta_project'
require_gem 'mime-types'
require_gem 'sqlite-ruby'
require_gem 'x10-cm17a'
if(DamageControl::Platform.family == "win32")
  require 'win32/sound'
end

require 'optparse'
require 'webrick'
require 'logger'
require 'fileutils'
require 'rscm'
require 'meta_project'
# http://wiki.rubyonrails.com/rails/pages/iconv
require 'iconv'

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
require 'damagecontrol/sqlite/retry'

# This is normally not needed, but we do it to avoid strange problems with const_missing
# that occur in the rubyscript2exe executables. Doesn't do any harm for conventional use.
require 'artifact'
require 'build'
require 'build_result_mailer'
require 'project'
require 'revision'
require 'revision_file'

exit if defined?(REQUIRE2LIB) # rubyscript2exe packaging mode

