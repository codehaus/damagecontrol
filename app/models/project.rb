require 'rgl/adjacency'
require 'rgl/connected_components'

# A Project record contains information about a project to be continuously
# built by DamageControl.
class Project < ActiveRecord::Base
  attr_reader :basedir

  has_many :revisions, :order => "timepoint DESC"
  has_many :publishers, :order => "delegate"
  has_and_belongs_to_many :dependencies, 
    :class_name => "Project", 
    :foreign_key => "depending_id", 
    :association_foreign_key => "dependant_id"
  has_and_belongs_to_many :dependants, 
    :class_name => "Project", 
    :foreign_key => "dependant_id", 
    :association_foreign_key => "depending_id"
  
  serialize :scm
  
  # Indicates that a build is complete (regardless of its successfulness)
  # Tells each enabled publisher to publish the build
  # and creates a build request for each dependant project
  def build_complete(build)
    logger.info "Build complete for #{name}'s revision #{build.revision.identifier}" if logger
    logger.info "Successful build: #{build.successful?}" if logger

    publishers.each do |publisher| 
      publisher.publish(build)
    end
    
    if(build.successful?)
      logger.info "Requesting build of dependant projects of #{name}: #{dependants.collect{|p| p.name}.join(',')}" if logger
      dependants.each do |project|
        project.create_build_request(Build::SUCCESSFUL_DEPENDENCY)
      end
    end
  end

  # Indicates that a build has started
  def build_executing(build)
    publishers.each do |publisher| 
      publisher.publish(build)
    end
  end
  
  def create_build_request(reason)
    last_revision = revisions[0]
    last_revision.builds.create(:reason => reason) #if last_revision
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
    
    create_missing_publishers
  end
  
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
  
  def create_missing_publishers
    associated_publisher_classes = publishers.collect{|publisher| publisher.delegate.class}
    available_publisher_classes = DamageControl::Publisher::Base.classes
    missing_publisher_classes = available_publisher_classes - associated_publisher_classes
    missing_publisher_classes.each do |cls|
      begin
        publishers.create(:delegate => cls.new)
      rescue
        $stderr.puts "Can't instantiate #{cls.name}"
      end
    end
  end
end
