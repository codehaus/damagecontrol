require File.dirname(__FILE__) + '/../../config/environment'
require 'damagecontrol/default_project_creator'
require 'damagecontrol/scm_poller'
require 'rscm'

scm_poller_thread = Thread.new do
  scm_poller = DamageControl::ScmPoller.new
  scm_poller.poll_all_projects
end
scm_poller_thread.join