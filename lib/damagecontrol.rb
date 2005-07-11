require 'rscm'
require 'damagecontrol/class_list'
require 'damagecontrol/publisher/base'
require 'damagecontrol/scm_web/base'
require 'damagecontrol/tracker/base'
require 'damagecontrol/scm_poller'
require 'damagecontrol/build_executor'
require 'damagecontrol/build_queue'

class Class
  def <=>(o)
    name <=> o.name
  end
end
