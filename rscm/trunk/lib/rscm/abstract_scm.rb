require 'fileutils'
require 'rscm/changes'
require 'xmlrpc/utils'

# WARNING - THIS DOCO IS CURRENTLY OUT OF DATE - PLEASE REFER TO THE README.
# 
# Base class for SCM (Source Control Management systems). In order to
# add support for a new SCM (let's say it's called Snoopy):
#
# 1) Implement SnoopyTest that includes GenericSCMTests and implements create_scm
#
# 2) Implement Snoopy < RSCM::AbstractSCM.
# Implement the following methods:
# (The methods that take a line_proc should yield each output line from 
# the underlying SCM command line (if appliccable))
#
# checkout(utc_time, &line_proc) -> Changesets
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
module RSCM
  class AbstractSCM
    include FileUtils
    
  public
  
    def create(&line_proc)      
    end

    def import(dir, message, &line_proc)
    end

    def trigger_installed?(trigger_command, trigger_files_checkout_dir, &line_proc)
    end

    def install_trigger(trigger_command, damagecontrol_install_dir, &line_proc)
    end

    def uninstall_trigger(trigger_command, trigger_files_checkout_dir, &line_proc)
    end

    # Checks out a working copy.
    #
    # checkout_dir: the local directory where the working copy will be checked out
    # scm_to_time: optional parameter. specifies the latest timestamp (in UTC) of
    # the files to check out. This timestamp should be according to the machine
    # where the SCM is running.
    #
    # The block will receive the checked out file names one by one.
    #
    # returns an array of strings, each representing the relative path of a checked
    # out file.
    # 
    # This method should not return or yield paths corresponding to
    # directories - only files.
    def checkout(checkout_dir, scm_to_time=nil, &file_proc)
    end

    def uptodate?(checkout_dir)
    end

    def can_create?
    end

    # The display name of this SCM
    def name
    end

    def label(checkout_dir, &line_proc)
    end
    
    def ==(other_scm)
      return false if self.class != other_scm.class
      self.instance_variables.each do |var|
        return false if self.instance_eval(var) != other_scm.instance_eval(var)
      end
      true
    end
 
    # Use this from checkout if it is a first checkout (and not "update" to use cvs terms)
    def most_recent_timestamp(changesets)
      most_recent = nil
      changesets.each do |changeset|
        if(changeset.time)
          most_recent = changeset.time if most_recent.nil? || most_recent < changeset.time
        else
          logger.warn("No time for changeset:")
          logger.warn(changeset)
        end
      end
      most_recent
    end

  protected

    def cmd(dir, cmd, &line_proc)
      if block_given? then yield "#{cmd}\n" else logger.debug("#{cmd}\n") end
      cmd_with_io(dir, cmd) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end

    def with_working_dir(dir)
      prev = Dir.pwd
      begin
        mkdir_p(dir)
        Dir.chdir(dir)
        yield
      ensure
        Dir.chdir(prev)
      end
    end

  end
end
