require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/Changes'
require 'xmlrpc/utils'

# Base class for SCM (Source Control Management systems). In order to
# add support for a new SCM (let's say it's called Snoopy):
#
# 1) Implement SnoopyTest that includes GenericSCMTests and implements create_scm
#
# 2) Implement Snoopy < DamageControl::AbstractSCM.
# Implement the following methods:
# (The methods that take a line_proc should yield each output line from 
# the underlying SCM command line (if appliccable))
#
# checkout(utc_time, &line_proc) -> nil
# changesets(utc_time, &line_proc) -> DamageControl::Changesets
# checkout(utc_time, &line_proc)
# atomic? -> [true|false] (TODO: avoid quiet period for atomic SCMs)
#
# 3) Implement LocalSnoopy < Snoopy. This is to support proper compliance testing
# as well as the possibility to create new repositories on the same machine as
# where the DC server will be running.
#
# Implement the following methods:
#
# create(&line_proc) -> nil
# import(dir, &line_proc) -> nil
#
# 4) (Optional) If the native SCM supports triggers, implement the following methods:
# (In either Snoopy or LocalSnoopy depending on the native trigger installation mechanism)
#
# can_install_trigger? -> true
# install_trigger(damagecontrol_install_dir, project_name, dc_xml_rpx_url) -> nil (throw ex on failure)
# uninstall_trigger(project_name) -> nil (throw ex on failure)
# trigger_installed?(project_name) -> [true|false]
#
# 5) implement snoopy_configure_form.erb
#
# 6) SnoopyWebConfigurator.rb
# (TODO - a generic test for this)
#
# 7) (optional) snoopy_declarations.js
#
# 8) Add your configurator to DamageControlServer.scm_configurator_classes
#
module DamageControl
  class AbstractSCM
    include FileUtils
    include Logging
    include XMLRPC::Marshallable
    
  public

    def checkout(checkout_dir, utc_time = nil, &proc)
    end

    def changesets(checkout_dir, from_time, to_time, &proc)
      ChangeSets.new
    end
    
    def uptodate?(checkout_dir, from_time, to_time, &proc)
      true
    end
    
    def label(checkout_dir, &proc)
      nil
    end
    
    def can_install_trigger?
      false
    end

    def exists?
      true
    end

    def trigger_installed?(project_name)
      false
    end

    def can_create?
      false
    end

    def trigger_command(damagecontrol_install_dir, project_name, trigger_xml_rpc_url="http://localhost:4712/private/xmlrpc", script_suffix="")
      script = "sh #{damagecontrol_install_dir}/bin/requestbuild#{script_suffix}"
      "#{script} --url #{trigger_xml_rpc_url} --projectname #{project_name}"
    end

    def ==(other_scm)
      return false if self.class != other_scm.class
      self.instance_variables.each do |var|
        return false if self.instance_eval(var) != other_scm.instance_eval(var)
      end
      true
    end

  protected

    def cmd(dir, cmd, &proc)
      if block_given? then yield "#{cmd}\n" else logger.debug("#{cmd}\n") end
      cmd_with_io(dir, cmd) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end
    
  end
end
