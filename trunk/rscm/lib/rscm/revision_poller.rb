module RSCM
  class Base
    attr_accessor :logger
  
    TWO_WEEKS_AGO = 2*7*24*60*60
    THIRTY_TWO_WEEKS_AGO = TWO_WEEKS_AGO * 16
    # Default time to wait for scm to be quiet (applies to non-transactional scms only)
    DEFAULT_QUIET_PERIOD = 15
    

    # Polls new revisions for since +last_revision+,
    # or if +last_revision+ is nil, polls since 'now' - +options[:seconds_before_now]+.
    # If no revisions are found AND the poll was using +options[:seconds_before_now]+
    # (i.e. it's the first poll, and no revisions were found),
    # calls itself recursively with twice the +options[:seconds_before_now]+.
    # This happens until revisions are found, ot until the +options[:seconds_before_now]+
    # Exceeds 32 weeks, which means it's probably not worth looking further in
    # the past, the scm is either completely idle or not yet active.
    def poll_new_revisions(options)
      options = {
        :latest_revision => nil, 
        :quiet_period => DEFAULT_QUIET_PERIOD, 
        :seconds_before_now => TWO_WEEKS_AGO, 
        :max_time_before_now => THIRTY_TWO_WEEKS_AGO,
      }.merge(options)
      max_past = Time.new.utc - options[:max_time_before_now]
  
      # Default value for start time (in case there are no detected revisions yet)
      from = Time.new.utc - options[:seconds_before_now]
      if(options[:latest_revision])
        from = options[:latest_revision].identifier
      else
        if(from < max_past)
          logger.info "Checked for revisions as far back as #{max_past}. There were none, so we give up." if logger
          return []
        else
          logger.info "Latest revision is not known. Checking for revisions since: #{from}" if logger
        end
      end

      logger.info "Polling revisions after #{from} (#{from.class.name})" if logger
      
      revisions = revisions(from, options)
      if(revisions.empty?)
        logger.info "No new revisions after #{from}" if logger
        unless(options[:latest_revision])
          double_seconds_before_now = 2*options[:seconds_before_now]
          logger.info "Last revision still not found, checking since #{double_seconds_before_now.ago}" if logger
          new_opts = options.dup
          new_opts[:seconds_before_now] = double_seconds_before_now
          return poll_new_revisions(new_opts)
        end
      else
        logger.info "There were #{revisions.length} new revision(s) after #{from}" if logger
      end

      if(!revisions.empty? && !transactional?)
        # We're dealing with a non-transactional SCM (like CVS/StarTeam/ClearCase,
        # unlike Subversion/Monotone). Sleep a little, get the revisions again.
        # When the revisions are not changing, we can consider the last commit done
        # and the quiet period elapsed. This is not 100% failsafe, but will work
        # under most circumstances. In the worst case, we'll miss some files in
        # the revisions for really slow commits, but they will be part of the next 
        # revision (on next poll).
        commit_in_progress = true
        while(commit_in_progress)
          logger.info "Sleeping for #{options[:quiet_period]} seconds because #{visual_name} is not transactional." if logger
          
          sleep(options[:quiet_period])
          previous_revisions = revisions
          revisions = revisions(from)
          commit_in_progress = revisions != previous_revisions
          if(commit_in_progress)
            logger.info "Commit still in progress." if logger
          end
        end
        logger.info "Quiet period elapsed" if logger
      end
      return revisions
    end
  end
end