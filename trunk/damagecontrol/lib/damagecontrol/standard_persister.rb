require 'rss/maker'
require 'rscm/logging'
require 'rscm/time_ext'
require 'damagecontrol/project'

module DamageControl
  # Persists standard stuff like revisions, diffs and RSS.
  # Typically used within a block passed to a Poller. See App.
  class StandardPersister
    
    # Save the revisions to disk as YAML
    def save_revisions(project, revisions)
      Log.info "Saving revisions for #{project.name}"
      revisions.accept(project.revisions_persister)
    end
    
    # Save RSS to disk. The RSS spec says max 15 items in a channel,
    # (http://www.chadfowler.com/ruby/rss/)
    # We'll get upto the latest 15 revisions and turn them into RSS.
    def save_rss(project)
      Log.info "Generating RSS for #{project.name}"
      last_15_revisions = project.revisions_persister.load_upto(project.revisions_persister.latest_identifier, 15)
      RSS::Maker.make("2.0") do |rss|
        FileUtils.mkdir_p(File.dirname(project.revisions_rss_file))
        File.open(project.revisions_rss_file, "w") do |io|
          rss_writer = DamageControl::Visitor::RssWriter.new(
            rss,
            "Revisions for #{project.name}",
            "http://localhost:4712/", # TODO point to web version of revision
            project.name, 
            project.tracker || Tracker::Null.new, 
            project.scm_web || SCMWeb::Null.new        
          )
          last_15_revisions.accept(rss_writer)
          io.write(rss.to_rss)
        end
      end
      Log.info "Saved RSS for #{project.name} to #{project.revisions_rss_file}"
    end
  end
end