require 'rgl/adjacency'
require 'rgl/connected_components'

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

  # Same as revisions[0], but faster since it only loads one record
  def latest_revision
    Revision.find_by_sql(["SELECT * FROM revisions WHERE project_id=? ORDER BY timepoint DESC LIMIT 1", self.id])[0]
  end

  # Finds the latest build +successful+ or not.
  # If the +before+ argument is specified (UTC time), 
  # the build's +begin_time+ will be before that time.
  def latest_build(successful=nil, before=nil)
    raise "successful must be bool" if successful && !(successful.class==TrueClass || successful.class==FalseClass)
    success_criterion = successful ? "AND b.exitstatus=0" : ""
    before_criterion = before ? "AND b.begin_time<#{quote(before)}" : ""
    
    sql = <<-EOS
SELECT b.* 
FROM builds b, revisions r, projects p 
WHERE r.project_id=?
AND b.revision_id=r.id 
AND b.exitstatus IS NOT NULL
#{success_criterion}
#{before_criterion}
ORDER BY b.begin_time DESC
LIMIT 1
    EOS

    Build.find_by_sql([sql, self.id])[0]
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
      publisher.publish_maybe(build)
    end
    
    if(build.successful?)
      logger.info "Requesting build of dependant projects of #{name}: #{dependants.collect{|p| p.name}.join(',')}" if logger
      dependants.each do |project|
        project.request_build(Build::SUCCESSFUL_DEPENDENCY)
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
  def request_build(reason)
    lr = latest_revision
    if(lr)
      lr.request_build(reason)
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
  end
  
  # Where temporary stdout log is written
  def stdout_file
    "#{@basedir}/stdout.log"
  end

  # Where temporary stderr log is written
  def stderr_file
    "#{@basedir}/stderr.log"
  end
  
private

  # creates dir if it doesn't exist and returns path to it
  def mkdir(dir)
    FileUtils.mkdir_p(dir) unless File.exist?(dir)
    dir
  end

end
