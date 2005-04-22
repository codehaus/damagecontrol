require 'fileutils'
require 'yaml'
require 'rscm'
require 'damagecontrol/changeset_ext'
require 'damagecontrol/diff_parser'
require 'damagecontrol/diff_htmlizer'
require 'damagecontrol/scm_web'
require 'damagecontrol/tracker'
require 'damagecontrol/visitor/yaml_persister'
require 'damagecontrol/visitor/diff_persister'
require 'damagecontrol/visitor/rss_writer'
require 'damagecontrol/publisher/base'

module ObjectTemplate
  def dupe(variables)
    template_yaml = YAML::dump(self)
    b = binding
    variables.each { |key, value| eval "#{key} = variables[\"#{key}\"]", b }
    new_yaml = eval(template_yaml.dump.gsub(/\\#/, "#"), b)
    YAML::load(new_yaml)
  end
end

module DamageControl

  # Represents a project with associated SCM, Tracker and SCMWeb
  class Project
    include ObjectTemplate
  
    # TODO: move to scms? not sure....
    DEFAULT_QUIET_PERIOD = 10 unless defined? DEFAULT_QUIET_PERIOD

    attr_accessor :name
    attr_accessor :home_page
    attr_accessor :start_time
    # Relative path from scm's checkout dir where build is executed from.
    attr_accessor :relative_execute_path

    attr_accessor :scm
    attr_accessor :tracker
    attr_accessor :scm_web

    # How long to sleep between each changesets invocation for non-transactional SCMs  
    attr_accessor :quiet_period
    
    attr_accessor :build_command
    attr_accessor :publishers
    
    # Loads the project with the given +name+.
    def Project.load(config_file)
      Log.info "Loading project from #{config_file}"
      project = File.open(config_file) do |io|
        YAML::load(io)
      end
      project.dir = File.dirname(config_file)
      project.scm.checkout_dir = "#{project.dir}/working_copy" if project.scm

      # Add new publishers that may have be defined after the project was YAMLed.
      project.publishers = [] if project.publishers.nil?
      Publisher::Base.classes.collect{|cls| cls.new}.each do |publisher|
        publisher_of_same_type = project.publishers.find do |p|
          p.class == publisher.class
        end
        project.publishers << publisher unless publisher_of_same_type
      end
      project
    end

    # Loads all projects
    def Project.find_all(projects_dir)
      Dir["#{projects_dir}/*/project.yaml"].collect do |config_file| 
        Project.load(config_file)
      end
    end
    
    def to_yaml_properties
      props = instance_variables
      props.delete("@dir")
      props.sort!
    end
    
    def initialize(name="")
      @name = name
      @publishers = Publisher::Base.classes.collect{|cls| cls.new}
      @scm = nil
      @tracker = Tracker::None.new
      # @scm_web = SCMWeb::None.new
      # Default start time is 2 weeks ago
      @start_time = Time.now.utc - (3600*24*14)
      @quiet_period = DEFAULT_QUIET_PERIOD
      @relative_execute_dir = "."
      @dependencies = []
    end
    
    # Lists all immediate dependencies of this project.
    def dependencies
      @dependencies ||= []
      result = @dependencies.collect do |project_name|
        if(@dir)
          config = "#{File.dirname(dir)}/#{project_name}/project.yaml"
          if(File.exist?(config))
            Project.load(config)
          else
            nil
          end
        else
          # Used in testing, when it's often too cumbersome to set up a dir
          Project.new(project_name)
        end
      end
      result.delete_if {|x| x.nil? } 
      result.freeze
      result
    end
    
    # Adds a dependency for this project
    def add_dependency(project)
      @dependencies ||= []
      raise "Circular dependency!" if(project.depends_on?(self))
      @dependencies << project.name
    end

    def clear_dependencies
      @dependencies ||= []
      @dependencies.clear
    end
    
    # Returns true if this project depends on +project+ (directly or indirectly)
    def depends_on?(project)
      depends_directly_on?(project) || depends_indirectly_on?(project)
    end
    
    # Returns true if and only if this project *indirectly* depends on +project+.
    def depends_directly_on?(project)
      dependencies.index(project) != nil
    end
    
    # Returns true if and only if this project *indirectly* depends on +project+.
    def depends_indirectly_on?(project)
      dependencies.find{|d| d.depends_on?(project)} != nil
    end
    
    # Sets the time of the first changeset to be retrieved for this project.
    # Will only be used for new projects, and only once.
    # TODO: rename to first_recorded_changeset_time
    def start_time=(t)
      t = Time.parse_ymdHMS(t) if t.is_a? String
      @start_time = t
    end

    def dir=(d)
      @dir = d
    end
    
    # The directory the project lives in. This is not serialised to yaml.
    def dir
      raise "dir not set" unless @dir
      @dir
    end
    
    # The directory where builds are executed from. Should be a relative path
    # from the root of the SCM's working copy directory.
    def execute_dir
      File.expand_path(@scm.checkout_dir + "/" + @relative_execute_dir)
    end

    # Tells all publishers to publish a build
    def publish(build)
      @publishers.each do |publisher| 
        begin
          if(publisher.enabled)
            Log.info("Publishing #{publisher.name} for #{@name}")
            publisher.publish(build) 
          else
            Log.info("Skipping disabled publisher #{publisher.name} for #{@name}")
          end
        rescue => e
          Log.error "Error running publisher #{publisher.name} for project #{name}"
          Log.error  e.message
          Log.error "  " + e.backtrace.join("  \n")
        end
      end
    end
    
    # Saves the state of this project to persistent store (YAML)
    def save
      f = project_config_file
      FileUtils.mkdir_p(File.dirname(f))
      File.open(f, "w") do |io|
        YAML::dump(self, io)
      end
    end
    
    # TODO: remove
    # Checks out files to project's checkout directory.
    # Writes the checked out files to +checkout_list_file+.
    # The +changeset_identifier+ parameter is a String or a Time
    # representing a changeset.
    def checkout(changeset_identifier)
      scm.checkout(changeset_identifier)
    end

    # TODO: pass quiet_period as arg here?
    # Polls SCM for new changesets and yields them to the given block.
    def poll
      latest_identifier = DamageControl::Visitor::YamlPersister.new(changesets_dir).latest_identifier
      from = latest_identifier || @start_time
      
      Log.info "Polling changesets for #{name}'s #{@scm.name} from #{from}"
      changesets = @scm.changesets(from)
      if(changesets.empty?)
        Log.info "No changesets for #{name}'s #{@scm.name} from #{from}"
      else
        Log.info "There were changesets for #{name}'s #{@scm.name} from #{from}"
      end
      if(!changesets.empty? && !@scm.transactional?)
        # We're dealing with a non-transactional SCM (like CVS/StarTeam/ClearCase,
        # unlike Subversion/Monotone). Sleep a little, get the changesets again.
        # When the changesets are not changing, we can consider the last commit done
        # and the quiet period elapsed. This is not 100% failsafe, but will work
        # under most circumstances. In the worst case, we'll miss some files in
        # the changesets for really slow commits, but they will be part of the next 
        # changeset (on next poll).
        commit_in_progress = true
        while(commit_in_progress)
          @quiet_period ||= DEFAULT_QUIET_PERIOD
          Log.info "Sleeping for #{@quiet_period} seconds since #{name}'s SCM (#{@scm.name}) is not transactional."
          sleep @quiet_period
          next_changesets = @scm.changesets(from)
          commit_in_progress = changesets != next_changesets
          changesets = next_changesets
        end
        Log.info "Quiet period elapsed for #{name}. Commit still in progress: #{commit_in_progress}"
      end
      changesets.each{|changeset| changeset.project = self}
      yield changesets
    end
    
    # Where RSS is written.
    def changesets_rss_file
      "#{dir}/changesets.xml"
    end

    # TODO: remove
    def checked_out?
      @scm.checked_out?
    end
    
    def exists?
      File.exists?(project_config_file)
    end

    # TODO: remove
    def scm_exists?
      scm.exists?
    end

    def delete_working_copy
      File.delete(scm.checkout_dir)
    end

    def changesets_rss_exists?
      File.exist?(changesets_rss_file)
    end

    def changesets_dir
      "#{dir}/changesets"
    end
    
    # Loads changesets and sets ourself as each changeset's project
    def changesets(changeset_identifier, prior)
      changesets = changesets_persister.load_upto(changeset_identifier, prior)
      # Establish child->parent (backwards) references
      changesets.each do |changeset| 
        changeset.project = self
        changeset.each do |change|
          change.changeset = changeset
        end
      end
      changesets
    end
    
    def latest_changeset
      changeset(latest_changeset_identifier)
    end

    def changeset(changeset_identifier)
      changesets(changeset_identifier, 1)[0]
    end

    def changeset_identifiers
      changesets_persister.identifiers
    end
    
    def latest_changeset_identifier
      changesets_persister.latest_identifier
    end
    
    def delete
      File.delete(dir)
    end
    
    def == (o)
      raise "name not defined!" if name.nil?
      return false unless o.is_a?(Project)
      raise "name not defined!" if o.name.nil?
      name == o.name
    end

    def changesets_persister
      DamageControl::Visitor::YamlPersister.new(changesets_dir)
    end

  private

    def project_config_file
      "#{dir}/project.yaml"
    end

  end
end
