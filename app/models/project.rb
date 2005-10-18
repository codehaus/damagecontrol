#require 'rgl/adjacency'
#require 'rgl/connected_components'
require 'set'
require 'rss/maker'
require 'rss/parser'
require 'damagecontrol/dom'

# A Project record contains information about a project to be continuously
# built by DamageControl.
class Project < ActiveRecord::Base
  
  include DamageControl::Dom
  attr_reader :basedir

  has_many :revisions, :order => "timepoint DESC", :dependent => true
  has_and_belongs_to_many :dependencies, 
    :class_name => "Project", 
    :join_table => "project_dependencies",
    :foreign_key => "from_id", 
    :association_foreign_key => "to_id",
    :order => "name"
  has_and_belongs_to_many :dependants, 
    :class_name => "Project", 
    :join_table => "project_dependencies",
    :foreign_key => "to_id", 
    :association_foreign_key => "from_id",
    :order => "name"
  
  has_and_belongs_to_many :build_executors, :order => "build_executor_id"

  serialize :scm
  serialize :scm_web
  serialize :tracker
  serialize :publishers
  serialize :generated_files

  def before_destroy
    begin
      scm.destroy_working_copy if scm
    rescue
    end
    FileUtils.rm_rf(@basedir) if File.exist?(@basedir)
  end

  def after_find
    set_defaults
  end

  def before_save
    set_defaults    
  end
  
  def after_save
    master = BuildExecutor.master_instance
    if(local_build)
      build_executors << master unless build_executors.index(master)
    else
      build_executors.delete(master)
    end
  end
  
  def initialize(*args)
    super(*args)
    self.scm_web = MetaProject::ScmWeb::Browser.new(
      "/revision_parser/dir/\#{path}",
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

  # Finds builds ordered in descending order of their +begin_time+. Valid options:
  #  * :exitstatus (Integer)
  #  * :before (UTC Time)
  #  * :pending (true/false)
  #  * :count (Integer)
  def builds(options={})
    default_options = {
      :exitstatus => nil, 
      :before => nil, 
      :pending => false,      
      :count => 1,
    }
    options = default_options.merge(options)

    exitstatus_criterion = options[:exitstatus] ? "AND b.exitstatus=0" : ""
    before_criterion = options[:before] ? "AND b.create_time<#{quote(options[:before])}" : ""
    pending_criterion = options[:pending] ? "AND b.state IS NULL" : ""
    
    sql = <<-EOS
SELECT DISTINCT b.* 
FROM builds b, revisions r, projects p 
WHERE r.project_id = ?
AND b.revision_id = r.id 
#{exitstatus_criterion}
#{before_criterion}
#{pending_criterion}
ORDER BY b.create_time DESC
LIMIT #{options[:count]}
    EOS

    Build.find_by_sql([sql, self.id])
  end
  
  def latest_build
    builds[0]
  end
  
  def latest_successful_build
    builds(:exitstatus => 0)[0]
  end
  
  def pending_builds
    builds(:pending => true)
  end

  def latest_revision_has_builds?
    latest_revision.builds.empty?
  end
  
  # Indicates that a build has started
  def build_executing(build)
    publishers.each do |publisher| 
      publisher.publish_maybe(build)
    end
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
        project.request_builds_for_latest_revision(Build::SUCCESSFUL_DEPENDENCY, build)
      end
    end
  end
  
  # Requests builds for the latest revision and returns those builds
  def request_builds_for_latest_revision(reason, triggering_build)
    lr = latest_revision
    if(lr)
      lr.request_builds(reason, triggering_build)
    end
  end

  def working_copy_dir
     File.expand_path("#{@basedir}/working_copy")
  end

  def zip_dir
     mkdir "#{@basedir}/zips"
  end

  def build_dir
    mkdir "#{working_copy_dir}/#{relative_build_path}"
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
      builds(:count => 15).each do |build|
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
  
  # Whether we could depend on +project+ without creating a cycle.
  def could_depend_on?(project)
    return false if project == self
    transitive_dependencies = Set.new
    project.accumulate_transitive_dependencies(transitive_dependencies)
    !transitive_dependencies.include?(self)
  end
  
  # Accumulates all dependencies into +set+
  def accumulate_transitive_dependencies(set)
    set.merge(dependencies)
    dependencies.each{|dep| dep.accumulate_transitive_dependencies(set)} unless set.include?(self)
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

  # Helper method for adding sound publisher
  def add_sound
    sound = DamageControl::Publisher::Sound.new
    sound.enabling_states = Build::COMPLETE_STATES
    publishers ||= []
    publishers << sound
  end

  # Helper method for adding Growl publisher
  def add_growl
    growl = DamageControl::Publisher::Growl.new
    growl.enabling_states = Build::STATES
    publishers ||= []
    publishers << growl
  end

  # DOM abstract methods

  def enabled
    true
  end

  def category
    "project"
  end

  def exclusive?
    false
  end
  
  # Populates from fields in a hash. The hash typically
  # comes from a HTTP request or a YAML file.
  def populate_from_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    
    attrs = hash.dup.delete_if do |k,v|
      !attribute_names.index(k.to_s) ||
      k.to_s == "scm" ||
      k.to_s == "tracker" ||
      k.to_s == "publishers" ||
      k.to_s == "scm_web"
    end

    self.update_attributes(attrs)

    self.scm        = hash[:scm].deserialize_to_array.find{|scm| scm.enabled}
    self.tracker    = hash[:tracker].deserialize_to_array.find{|tracker| tracker.enabled}
    self.publishers = hash[:publisher].deserialize_to_array

    self.scm_web = MetaProject::ScmWeb::Browser.new
    self.scm_web.dir_spec      = hash[:scm_web][:dir_spec]
    self.scm_web.history_spec  = hash[:scm_web][:history_spec]
    self.scm_web.raw_spec      = hash[:scm_web][:raw_spec]
    self.scm_web.html_spec     = hash[:scm_web][:html_spec]
    self.scm_web.diff_spec     = hash[:scm_web][:diff_spec]

    self.dependencies.clear
    if(hash[:project_dependencies])
      hash[:project_dependencies].each do |project_id|
        p = Project.find(project_id)
        if(self.could_depend_on?(p))
          self.dependencies << p
        end
      end
    end
  end
  
  def export_to_hash
    attributes
  end

private

  def set_defaults
    @basedir = File.expand_path("#{DC_DATA_DIR}/projects/#{id}")
    FileUtils.mkdir_p @basedir unless File.exist?(@basedir)
    self.scm.checkout_dir = working_copy_dir if self.scm
    self.scm.enabled = true if self.scm
    self.tracker.enabled = true if self.tracker
  end

  # creates dir if it doesn't exist and returns path to it
  def mkdir(dir)
    FileUtils.mkdir_p(dir) unless File.exist?(dir)
    dir
  end
  
end
