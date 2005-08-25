#require 'rgl/adjacency'
#require 'rgl/connected_components'
require 'rss/maker'
require 'rss/parser'
require 'damagecontrol'

# A Project record contains information about a project to be continuously
# built by DamageControl.
class Project < ActiveRecord::Base
  attr_reader :basedir

  has_many :revisions, :order => "timepoint DESC"
  has_and_belongs_to_many :dependencies, 
    :class_name => "Project", 
    :foreign_key => "depending_id", 
    :association_foreign_key => "dependant_id"
  has_and_belongs_to_many :dependants, 
    :class_name => "Project", 
    :foreign_key => "dependant_id", 
    :association_foreign_key => "depending_id"
  
  serialize :scm
  serialize :scm_web
  serialize :tracker
  serialize :publishers

  # Returns an RGL::DirectedAdjacencyGraph representing all projects
  # and their dependencies
  def self.dependency_graph
    g = RGL::DirectedAdjacencyGraph.new
    self.find(:all).each do |from|
      from.dependencies.each do |to|
        g.add_edge(from, to)
      end
    end
    g
  end

  def initialize(*args)
    super(*args)
    self.scm_web = MetaProject::ScmWeb.new(
      "/revision_parser/overview",
      "/revision_parser/history/\#{path}",
      "/revision_parser/raw/\#{path}?revision=\#{revision}",
      "/revision_parser/html/\#{path}?revision=\#{revision}",
      "/revision_parser/diff/\#{path}?previous_revision=\#{previous_revision}&?revision=\#{revision}"
    ) if self.scm_web.nil?
    
    self.tracker = MetaProject::Tracker::NullTracker.new if self.tracker.nil?
  end

  # Same as revisions[0], but faster since it only loads one record
  def latest_revision
    latest_revisions(1)[0]
  end

  # The +count+ latest revisions ordered by descending timepoint
  def latest_revisions(count)
    Revision.find_by_sql(["SELECT * FROM revisions WHERE project_id=? ORDER BY timepoint DESC LIMIT ?", self.id, count])
  end

  # Finds builds (+successful+ or not), ordered in descending order of their +begin_time+.
  # If the +before+ argument is specified (UTC time), 
  # the builds' +begin_time+ will be before that time.
  # The number of returned builds will be maximum +max_count+.
  def builds(successful=nil, before=nil, max_count=1)
    raise "successful must be bool" if successful && !(successful.class==TrueClass || successful.class==FalseClass)
    success_criterion = successful ? "AND b.exitstatus=0" : ""
    before_criterion = before ? "AND b.begin_time<#{quote(before)}" : ""
    
    sql = <<-EOS
SELECT DISTINCT b.* 
FROM builds b, revisions r, projects p 
WHERE r.project_id=?
AND b.revision_id=r.id 
AND b.exitstatus IS NOT NULL
#{success_criterion}
#{before_criterion}
ORDER BY b.begin_time DESC
LIMIT #{max_count}
    EOS

    Build.find_by_sql([sql, self.id])
  end

  def latest_revision_has_builds?
    latest_revision.builds.empty?
  end
  
  # Indicates that a build is complete (regardless of its successfulness)
  # Tells each enabled publisher to publish the build
  # and creates a build request for each dependant project
  def build_complete(build)
    logger.info "Build complete for #{name}'s revision #{build.revision.identifier}" if logger
    logger.info "Successful build: #{build.successful?}" if logger

    publishers.each do |publisher| 
      begin
        publisher.publish_maybe(build)
      rescue => e
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
      end
    end
    
    # TODO: Make this a post-build task
    if(build.successful?)
      logger.info "Requesting build of dependant projects of #{name}: #{dependants.collect{|p| p.name}.join(',')}" if logger
      dependants.each do |project|
        project.request_build(Build::SUCCESSFUL_DEPENDENCY, build)
      end
    end
  end

  # Indicates that a build has started
  def build_executing(build)
    publishers.each do |publisher| 
      publisher.publish_maybe(build)
    end
  end
  
  # Creates a new (pending) build for the latest revision
  # of this project. Returns the created Build object.
  def request_build(reason, triggering_build=nil)
    lr = latest_revision
    if(lr)
      lr.request_build(reason, triggering_build)
    else
      nil
    end
  end
  
  def working_copy_dir
     mkdir "#{@basedir}/working_copy"
  end

  def build_dir
    mkdir "#{working_copy_dir}/#{relative_build_path}"
  end

  def after_find
    @basedir = "#{DAMAGECONTROL_HOME}/projects/#{id}"
    mkdir @basedir
    self.scm.checkout_dir = working_copy_dir unless self.scm.nil?

    self.scm.enabled = true unless self.scm.nil?
    self.tracker.enabled = true unless self.tracker.nil?
  end
  
  # Where temporary stdout log is written
  def stdout_file
    "#{@basedir}/stdout.log"
  end

  # Where temporary stderr log is written
  def stderr_file
    "#{@basedir}/stderr.log"
  end
  
  def revisions_rss(controller, rss_version="2.0")
    rss = RSS::Maker.make(rss_version) do |maker|
      maker.channel.title = "#{name} revisions"
      maker.channel.link =  controller.url_for(:controller => "project", :action => "show", :id => id)
      maker.channel.description = "#{name} revisions"
      maker.channel.generator = "DamageControl"

      #maker.channel.language = "language"
      #maker.image.url = "maker.image.url"
      #maker.image.title = "maker.image.title"

      # The RSS spec says max 15 items
      latest_revisions(15).each do |revision|
        item = maker.items.new_item

        item.pubDate = revision.timepoint
        item.author = revision.developer
        item.title = "Revision #{revision.identifier}: #{revision.message}"
        item.link = controller.url_for(:controller => "revision", :action => "show", :id => revision.id)
        item.description = "<b>#{revision.developer}</b><br/>\n"
        item.description << revision.message.gsub(/\n/, "<br/>\n") << "<p/>\n"
        
        revision.revision_files.each do |file|
          # TODO: make internal(expandable) or external links to file diffs
          item.description << "#{file.path}<br/>\n"
        end
      end
    end
    rss.to_s
  end
  
  def builds_rss(controller, rss_version="2.0")
    rss = RSS::Maker.make(rss_version) do |maker|
      maker.channel.title = "#{name} builds"
      maker.channel.link =  controller.url_for(:controller => "project", :action => "show", :id => id)
      maker.channel.description = "#{name} builds"
      maker.channel.generator = "DamageControl"

      #maker.channel.language = "language"
      #maker.image.url = "maker.image.url"
      #maker.image.title = "maker.image.title"

      # The RSS spec says max 15 items
      builds(nil, nil, 15).each do |build|
        item = maker.items.new_item

        item.pubDate = build.begin_time
        item.author = build.owner
        item.title = "#{build.state.description} build (#{build.reason_description}, revision #{build.revision.identifier})"
        item.link = controller.url_for(:controller => "build", :action => "show", :id => build.id)
        
        headline = "#{build.revision.project.name}: #{build.state.description} build (#{build.reason_description})"
        item.description = "<b>#{headline}</b><br/>\n"

        # We have to use detect and not find. find seems to collide with AR.
        primary_artifact = build.artifacts.detect{|a| a.is_primary}
        if(primary_artifact)
          # TODO: make visible link
          item.description << "#{primary_artifact.relative_path}<br/>\n"

          enclosure = item.enclosure
          item.enclosure.url = controller.url_for(:controller => "file_system", :action=> "artifacts", :params => {:path => primary_artifact.relative_path.split('/')})
          enclosure.length = primary_artifact.file.size
          enclosure.type = primary_artifact.file.type
        end
      end
    end
    rss.to_s
  end
  
  # RSS for this project. Contains a mix of revision and build items
  def rss(controller, rss_version="2.0")
    # http://www.cozmixng.org/~rwiki/?cmd=view;name=RSS+Parser%3A%3ATutorial.en
    # http://www.ruby-lang.org/cgi-bin/cvsweb.cgi/ruby/sample/rss/blend.rb?rev=1.2
    feeds = []
    feeds << RSS::Parser.parse(revisions_rss(controller, rss_version), false)
    feeds << RSS::Parser.parse(builds_rss(controller, rss_version), false)
    
    rss = RSS::Maker.make(rss_version) do |maker|
      maker.channel.title = "#{name} builds and revisions"
      maker.channel.link =  controller.url_for(:controller => "project", :action => "show", :id => id)
      maker.channel.description = "#{name} builds and revisions"
      maker.channel.generator = "DamageControl"
      
      feeds.each do |feed|
        feed.items.each do |item|
          item.setup_maker(maker)
        end
      end
      maker.items.do_sort = true
      maker.items.max_size = 15
    end
    rss.to_s
  end

  include ::DamageControl::Dom

  def enabled
    true
  end

  def category
    "project"
  end

  def exclusive?
    false
  end

private

  # creates dir if it doesn't exist and returns path to it
  def mkdir(dir)
    FileUtils.mkdir_p(dir) unless File.exist?(dir)
    dir
  end

end
