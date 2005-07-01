require 'rgl/adjacency'
require 'rgl/connected_components'

class Project < ActiveRecord::Base
  has_many :revisions, :order => "timepoint"
  has_many :publishers
  has_and_belongs_to_many :dependencies, 
    :class_name => "Project", 
    :foreign_key => "depending_id", 
    :association_foreign_key => "dependant_id"
  has_and_belongs_to_many :dependants, 
    :class_name => "Project", 
    :foreign_key => "dependant_id", 
    :association_foreign_key => "depending_id"
  
  serialize :scm
  
  # Indicates that a build is complete
  # Tells each enabled publisher to publish the build
  # and creates a build request for each dependant project
  def build_complete(build)
    publishers.each do |publisher| 
      publisher.publish(build) if publisher.enabled
    end
    
    if(build.successful?)
      dependants.each do |project|
        project.create_build_request("Successful build of dependant project #{self.name}")
      end
    end
  end
  
  def create_build_request(reason)
    last_revision = revisions[-1]
    last_revision.builds.create(:reason => reason) if last_revision
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
  
private

  # creates dir if it doesn't exist and returns path to it
  def mkdir(dir)
    FileUtils.mkdir_p(dir) unless File.exist?(dir)
    dir
  end
end
