require 'rscm'
require 'damagecontrol/plugin'
require 'damagecontrol/publisher/base'
require 'damagecontrol/scm_web/base'
require 'damagecontrol/tracker/base'
require 'damagecontrol/scm_poller'
require 'damagecontrol/build_executor'
require 'damagecontrol/build_queue'
require 'damagecontrol/build_daemon'

class Class
  def <=>(o)
    name <=> o.name
  end
end
