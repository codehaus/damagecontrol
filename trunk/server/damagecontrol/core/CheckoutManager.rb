require 'damagecontrol/util/Logging'

module DamageControl

  # Asks SCM to check out and updates project configs with latest commit time.
  # Also performs some filtering of changesets to avoid getting too much in case
  # the latest commit time hasn't yet been computed.
  #
  # The two classes that typically use this class are SCMPoller and Trigger
  #
  class CheckoutManager
    include Logging
    
    def initialize(hub, project_directories, project_config_repository, build_history_repository)
      @hub = hub
      @project_directories = project_directories
      @project_config_repository = project_config_repository
      @build_history_repository = build_history_repository
    end

    # Checks out and updates project config's latest commit time. Returns one of the following:
    #
    # a) latest commit time (if this was the 1st checkout)
    # b) changesets (if there were changesets and checkout has been done previously)
    #    UNLESS the last_commit_time is nil - we don't want to risk getting changesets
    #    for the entire history of the project
    # c) nil if we're uptodate
    #
    def checkout(project_name)
      scm = @project_config_repository.create_scm(project_name)
      last_completed_build = @build_history_repository.last_completed_build(project_name)

      project_config = @project_config_repository.project_config(project_name)
      checkout_dir = @project_directories.checkout_dir(project_name)
      last_commit_time = project_config["last_commit_time"]
      scm_from_time = nil
      if(last_commit_time)
        scm_from_time = last_commit_time + 1
      end

      logger.info("Checking out project #{project_name}")

      # If first checkout: timestamp of last commit, otherwise, chagesets
      changesets_or_last_commit_time = scm.checkout(checkout_dir, scm_from_time, nil) do |line|
        # TODO: it would be nice to get each update as a block arg, and then send ProjectCheckoutMessage to the hub.
        # (It would not be associated with a build, but a project)
      end
      if(scm_from_time.nil? && !changesets_or_last_commit_time.is_a?(Time))
        last_commit_time = scm.most_recent_timestamp(changesets_or_last_commit_time)
        logger.info("Did checkout of #{project_name} before knowing last commit time. Found out it was at #{last_commit_time}")
        update_last_commit_time(project_name, last_commit_time, project_config)
      elsif(changesets_or_last_commit_time.is_a?(Time))
        logger.info("First checkout of #{project_name}. Last commit was at #{changesets_or_last_commit_time}")
        update_last_commit_time(project_name, changesets_or_last_commit_time, project_config)
        return changesets_or_last_commit_time
      elsif(changesets_or_last_commit_time.nil? || changesets_or_last_commit_time.empty?)
        logger.info("No changes in #{project_name}")
        return nil
      else
        last_commit_time = scm.most_recent_timestamp(changesets_or_last_commit_time)
        logger.info("Changes in #{project_name}. Number of changesets: #{changesets_or_last_commit_time.length}.")
        update_last_commit_time(project_name, last_commit_time, project_config)
        return changesets_or_last_commit_time
      end
    end

  private

    def update_last_commit_time(project_name, last_commit_time, project_config)
      project_config["last_commit_time"] = last_commit_time
      @project_config_repository.modify_project_config(project_name, project_config)
    end
    
  end
end