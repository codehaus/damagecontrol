require 'fileutils'
require 'yaml'
require 'rscm'
require 'damagecontrol/build'
require 'damagecontrol/directories'
require 'damagecontrol/diff_parser'
require 'damagecontrol/diff_htmlizer'
require 'damagecontrol/scm_web'
require 'damagecontrol/tracker'
require 'damagecontrol/visitor/yaml_persister'
require 'damagecontrol/visitor/diff_persister'
require 'damagecontrol/visitor/rss_writer'
require 'damagecontrol/publisher/base'

module DamageControl
  # Represents a project with associated SCM, Tracker and SCMWeb
  class Project

    attr_accessor :name
    attr_accessor :description
    attr_accessor :home_page

    attr_accessor :scm
    attr_accessor :tracker
    attr_accessor :scm_web

    # How long to sleep between each changesets invocation for non-transactional SCMs  
    attr_accessor :quiet_period

    attr_accessor :build_command
    attr_accessor :publishers

    # Loads the project with the given +name+.
    def Project.load(name)
      config_file = Directories.project_config_file(name)
      Log.info "Loading project from #{config_file}"
      project = File.open(config_file) do |io|
        YAML::load(io)
      end

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
    def Project.find_all
      Directories.project_names.collect do |name|
        Project.load(name)
      end
    end
    
    def initialize(name=nil)
      @name = name
      @publishers = Publisher::Base.classes.collect{|cls| cls.new}
      @scm = nil
      @tracker = Tracker::Null.new
      @scm_web = SCMWeb::Null.new
    end
    
    # Tells all publishers to publish a build
    def publish(build)
      @publishers.each { |publisher| publisher.publish(build) }
    end
    
    # Saves the state of this project to persistent store (YAML)
    def save
      f = project_config_file
      FileUtils.mkdir_p(File.dirname(f))
      File.open(f, "w") do |io|
        YAML::dump(self, io)
      end
    end
    
    # Path to file containing pathnames of latest checked out files.
    def checkout_list_file
      Directories.checkout_list_file(name)
    end
    
    # Checks out files to project's checkout directory.
    # Writes the checked out files to +checkout_list_file+.
    # The +changeset_identifier+ parameter is a String or a Time
    # representing a changeset.
    def checkout(changeset_identifier)
      File.open(checkout_list_file, "w") do |f|
        scm.checkout(checkout_dir, changeset_identifier) do |file_name|
          f << file_name << "\n"
          f.flush
        end
      end
    end

    # Polls SCM for new changesets and yields them to the given block.
    def poll(from_if_first_poll=Time.epoch)
      start = Time.now
      from = next_changeset_identifier || from_if_first_poll
      
      Log.info "Getting changesets for #{name} from #{from} (retrieved from #{checkout_dir})"
      changesets = @scm.changesets(checkout_dir, from)
      if(!changesets.empty? && !@scm.transactional?)
        # We're dealing with a non-transactional SCM (like CVS/StarTeam/ClearCase,
        # unlike Subversion/Monotone). Sleep a little, get the changesets again.
        # When the changesets are not changing, we can consider the last commit done
        # and the quiet period elapsed. This is not 100% failsafe, but will work
        # under most circumstances. In the worst case, we'll miss some files in
        # the changesets, but they will be part of the next changeset (on next poll).
        commit_in_progress = true
        while(commit_in_progress)
          @quiet_period ||= 5
          Log.info "Sleeping for #{@quiet_period} seconds since #{name}'s SCM (#{@scm.name}) is not transactional."
          sleep @quiet_period
          next_changesets = @scm.changesets(checkout_dir, from)
          commit_in_progress = changesets != next_changesets
          changesets = next_changesets
        end
        Log.info "Quiet period elapsed for #{name}"
      end
      Log.info "Got changesets for #{@name} in #{Time.now.difference_as_text(start)}"
      yield changesets
    end

    # Returns the identifier (int label or time) that should be used to get the next (unrecorded)
    # changeset. This is the identifier *following* the latest recorded changeset. 
    # This identifier is determined by looking at the directory names under 
    # +changesets_dir+. If there are none, this method returns nil.
    def next_changeset_identifier(d=changesets_dir)
      # See String extension at top of this file.
      latest_identifier = DamageControl::Visitor::YamlPersister.new(d).latest_identifier
      latest_identifier ? latest_identifier + 1 : nil
    end
    
    # Where RSS is written.
    def changesets_rss_file
      Directories.changesets_rss_file(name)
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
      Directories.checkout_dir(name)
    end
    
    def delete_working_copy
      File.delete(checkout_dir)
    end

    def changesets_rss_exists?
      File.exist?(changesets_rss_file)
    end

    def changesets_dir
      Directories.changesets_dir(name)
    end
    
    def changesets(changeset_identifier, prior)
      changesets_persister.load_upto(changeset_identifier, prior)
    end

    def changeset(changeset_identifier)
      result = changesets(changeset_identifier, 1)[0]
      raise "No changeset with id '#{changeset_identifier}' for project '#{name}'" unless result
      result
     end

    def changeset_identifiers
      changesets_persister.identifiers
    end
    
    def latest_changeset_identifier
      changesets_persister.latest_identifier
    end
    
    def delete
      File.delete(Directories.project_dir(name))
    end
    
    def == (o)
      return false unless o.is_a?(Project)
      name == o.name
    end

    def changesets_persister
      DamageControl::Visitor::YamlPersister.new(changesets_dir)
    end
    
    # Creates, persists and executes a Build for the changeset with the given 
    # +changeset_identifier+.
    # Should be called with a block of arity 1 that will receive the build.
    def execute_build(changeset_identifier, build_reason)
      scm.checkout(checkout_dir, changeset_identifier)
      build = Build.new(name, changeset_identifier, Time.now.utc, build_reason)
      yield build
    end

    # Returns an array of existing Build s for the given +changeset_identifier+.
    def builds(changeset_identifier)
      Directories.build_dirs(name, changeset_identifier).collect do |dir|
        # The dir's basename will always be a Time
        Build.new(name, changeset_identifier, File.basename(dir).to_identifier, "TODO: get from file")
      end
    end

    # Returns the Build for the given +changeset_identifier+ and +build_time+
    def build(changeset_identifier, build_time)
      Build.new(name, changeset_identifier, build_time, "FIXME")
    end

    # Returns the latest build.
    def latest_build
      changeset_identifiers.reverse.each do |changeset_identifier|
        builds = builds(changeset_identifier)
        return builds[-1] unless builds.empty?
      end
      nil
    end

  private

    def project_config_file
      Directories.project_config_file(name)
    end

  end
end
