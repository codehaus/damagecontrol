require 'rubygems'
require 'rscm'
require 'cgi'
require 'yaml'
require 'rss/maker'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildSerializer'
require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'
require 'damagecontrol/scm/NoTracker'
require 'pebbles/Space'
require 'pebbles/TimeUtils'

# Captures and persists build history.
# All reads are from memory, which is populated from files at startup.
# Writes will update memory as well as files.
#
# Instances of this class can also be reached
# through XML-RPC - See xmlrpc/StatusPublisher.rb
# 
# Authors: Steven Meyfroidt, Aslak Hellesoy, Jon Tirsen
module DamageControl

  class BuildHistoryRepository < Pebbles::Space

    include FileUtils
    include Logging

    # TODO: delete in a later release (plus the BWC stash at the bottom)
    # This will upgrade the old yamls to use new RSCM class names
    def upgrade_all
      @project_directories.project_names.each do |project_name|
        history = history(project_name, true)
        history.each do |build|
          register(build)
        end
      end
    end

    def initialize(channel, project_directories, build_serializer)
      super
      channel.add_consumer(self)
      @project_directories = project_directories
      @build_serializer = build_serializer
    end
    
    def on_message(message)
      if message.is_a?(BuildEvent) && !message.is_a?(StandardOutEvent)
        register(message.build)
      end
    end
    
    # TODO rename to dump (more aligned with YAML terminology - we're doing a similar thing)
    def register(build)
      build_dir = @project_directories.build_dir(build.project_name, build.dc_creation_time)
      @build_serializer.dump(build, build_dir)
      write_rss(build.project_name)
    end
    
    def history(project_name, with_changesets=false)
      @project_directories.build_dirs(project_name).collect do |build_dir|
        @build_serializer.load(build_dir, with_changesets)
      end
    end

    def lookup(project_name, dc_creation_time, with_changesets=false)
      build_dir = @project_directories.build_dir(project_name, dc_creation_time)
      @build_serializer.load(build_dir, with_changesets)
    end

    def current_build(project_name, with_changesets=false)
      @project_directories.build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, with_changesets)
        return build unless build.status == Build::QUEUED
      end
      nil
    end
    
    def last_completed_build(project_name, with_changesets=false)
      @project_directories.build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, with_changesets)
        return build if build.completed?
      end
      nil
    end
    
    # Returns the commit time for the last build that had a registered commit time
    # or nil if none was found.
    def last_commit_time(project_name)
      result = nil
      @project_directories.build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, false)
        if build.scm_commit_time
          logger.info("Last recorded commit time for #{project_name} was #{build.scm_commit_time} (build id: #{build.dc_creation_time.ymdHMS})")
          return build.scm_commit_time
        end
      end
      logger.info("No recorded commit time for #{project_name}")
      nil
    end
    
    def last_successful_build(project_name, with_changesets=false)
      @project_directories.build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, with_changesets)
        return build if build.successful?
      end
      nil
    end
    
    def next(build, with_changesets=false)
      return nil unless build
      @project_directories.build_dirs(build.project_name).each do |build_dir|
        b = @build_serializer.load(build_dir, with_changesets)
        return b if b.dc_creation_time > build.dc_creation_time
      end
      nil
    end

    def prev(build, with_changesets=false)
      return nil unless build
      @project_directories.build_dirs(build.project_name).reverse.each do |build_dir|
        b = @build_serializer.load(build_dir, with_changesets)
        return b if b.dc_creation_time < build.dc_creation_time
      end
      nil
    end

    def to_rss(project_name)
      File.new(@project_directories.rss_file(project_name)).read
    end
    
    # TODO: figure out whether to keep this in BHR or here!!!
    def project_config(project_name)
      config_map = File.open(@project_directories.project_config_file(project_name)) do |io|
        YAML::load(io)
      end
      config_map["project_name"] = project_name
      config_map
    end
    
  private
  
    # Writes rss to disk
    def write_rss(project_name)
      RSS::Maker.make("2.0") do |rss|
        rss.channel.title = "#{project_name} builds"
        rss.channel.description = rss.channel.title
        rss.channel.link = "#{@html_url}public/project/#{CGI.escape(project_name)}"
        rss.channel.generator = "DamageControl"

        project_config = project_config(project_name)
        message_linker = project_config["tracking"] || RSCM::Tracker::Null.new
        change_linker = project_config["scm_web"] || RSCM::SCMWeb::Null.new
        history(project_name, true).reverse.each do |build|
          item = rss.items.new_item
          build.populate(item, message_linker, change_linker)
        end

        File.open(@project_directories.rss_file(project_name), "w") do |io|
          io.puts(rss.to_rss)
        end
      end
    end

  end
end
