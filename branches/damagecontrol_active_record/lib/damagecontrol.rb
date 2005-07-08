require 'rscm'
require 'damagecontrol/build_executor'
require 'damagecontrol/build_queue'
require 'damagecontrol/publisher'
require 'damagecontrol/scm_web'
require 'damagecontrol/scm_poller'

class Class
  def <=>(o)
    name <=> o.name
  end
end
