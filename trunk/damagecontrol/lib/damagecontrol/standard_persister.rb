require 'rss/maker'
require 'rscm/logging'
require 'rscm/time_ext'
require 'damagecontrol/project'

module DamageControl
  # Persists standard stuff like changesets, diffs and RSS.
  # Typically used within a block passed to a Poller. See App.
  class StandardPersister
    
    # Save the changesets to disk as YAML
    def save_changesets(project, changesets)
      Log.info "Saving changesets for #{project.name}"
      changesets.accept(project.changesets_persister)
    end
    
    # Get the diffs for each change and save them.
    def save_diffs(project, changesets)
      Log.info "Getting diffs for #{project.name}"
      dp = DamageControl::Visitor::DiffPersister.new(project.scm, project.name)
      changesets.accept(dp)
      Log.info "Saved diffs for #{project.name}"
    end
    
    # Save RSS to disk. The RSS spec says max 15 items in a channel,
    # (http://www.chadfowler.com/ruby/rss/)
    # We'll get upto the latest 15 changesets and turn them into RSS.
    def save_rss(project)
      Log.info "Generating RSS for #{project.name}"
      last_15_changesets = project.changesets_persister.load_upto(project.changesets_persister.latest_id, 15)
      RSS::Maker.make("2.0") do |rss|
        FileUtils.mkdir_p(File.dirname(project.changesets_rss_file))
        File.open(project.changesets_rss_file, "w") do |io|
          rss_writer = DamageControl::Visitor::RssWriter.new(
            rss,
            "Changesets for #{@name}",
            "http://localhost:4712/", # TODO point to web version of changeset
            project.description, 
            project.tracker || Tracker::Null.new, 
            project.scm_web || SCMWeb::Null.new        
          )
          last_15_changesets.accept(rss_writer)
          io.write(rss.to_rss)
        end
      end
      Log.info "Saved RSS for #{project.name} to #{project.changesets_rss_file}"
    end
  end
end