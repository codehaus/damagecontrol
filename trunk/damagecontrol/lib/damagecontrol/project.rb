require 'fileutils'
require 'yaml'
require 'rscm'
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
    
    def initialize(name="")
      @name = name
      @publishers = Publisher::Base.classes.collect{|cls| cls.new}
      @scm = nil
      @tracker = Tracker::None.new
      # @scm_web = SCMWeb::None.new
      # Default start time is 2 weeks ago
      @start_time = Time.now.utc - (3600*24*14)
      @quiet_period = DEFAULT_QUIET_PERIOD
    end
    
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
    
    def to_yaml_properties
      props = instance_variables
      props.delete("@dir")
      props.sort!
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
    
    # Checks out files to project's checkout directory.
    # Writes the checked out files to +checkout_list_file+.
    # The +changeset_identifier+ parameter is a String or a Time
    # representing a changeset.
    def checkout(changeset_identifier)
      scm.checkout(checkout_dir, changeset_identifier)
    end

    # Polls SCM for new changesets and yields them to the given block.
    def poll
      start = Time.now
      from = next_changeset_identifier(changesets_dir) || @start_time
      
      Log.info "Polling changesets for #{name}'s #{@scm.name} from #{from}"
      changesets = @scm.changesets(checkout_dir, from)
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
          next_changesets = @scm.changesets(checkout_dir, from)
          commit_in_progress = changesets != next_changesets
          changesets = next_changesets
        end
        Log.info "Quiet period elapsed for #{name}"
      end
      changesets.each{|changeset| changeset.project = self}
      Log.info "Got changesets for #{@name} in #{Time.now.difference_as_text(start)}"
      yield changesets
    end

    # Returns the identifier (int label or time) that should be used to get the next (unrecorded)
    # changeset. This is the identifier *following* the latest recorded changeset. 
    # This identifier is determined by looking at the directory names under 
    # +changesets_dir+. If there are none, this method returns nil.
    def next_changeset_identifier(d)
      # See String extension at top of this file.
      latest_identifier = DamageControl::Visitor::YamlPersister.new(d).latest_identifier
      latest_identifier ? latest_identifier + 1 : nil
    end
    
    # Where RSS is written.
    def changesets_rss_file
      "#{dir}/changesets.xml"
    end

    def checked_out?
      @scm.checked_out?(checkout_dir)
    end
    
    def exists?
      File.exists?(project_config_file)
    end

    def scm_exists?
      scm.exists?
    end

    def checkout_dir
      "#{dir}/checkout"
    end
    
    def delete_working_copy
      File.delete(checkout_dir)
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
      return false unless o.is_a?(Project)
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
