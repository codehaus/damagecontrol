require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildEvents'
require 'damagecontrol/core/ProjectDirectories'
require 'damagecontrol/scm/Changes'
require 'damagecontrol/util/Logging'
require 'pebbles/Space'
require 'pebbles/TimeUtils'
require 'rexml/document'
require 'yaml'

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

    include Logging

    def initialize(channel, project_directories=nil)
      super
      channel.add_consumer(self)
      @project_directories = project_directories
      @history = {}
      
      if(@project_directories)
        populate_cache_from_files
      end
    end
    
    def current_build(project_name)
      history = history(project_name)
      return nil unless history
      history.reverse.find {|b| b.status != Build::QUEUED }
    end
    
    def last_completed_build(project_name)
      history = history(project_name)
      return nil unless history
      history.reverse.find {|build| build.completed?}
    end
    
    def last_successful_build(project_name)
      history = history(project_name)
      return nil unless history
      history.reverse.find {|build| build.status == Build::SUCCESSFUL}
    end

    def on_message(message)
      if message.is_a?(BuildEvent) && !message.is_a?(BuildProgressEvent)
        register(message.build)
      end
    end
    
    def build_with_number(project_name, label)
      history(project_name).find {|b| b.label.to_s == label.to_s }
    end
    
    def history(project_name)
      return [] unless @history.has_key?(project_name)
      result = @history[project_name]
      result
    end

    def lookup(project_name, dc_creation_time)
      dc_creation_time = Time.parse_ymdHMS(dc_creation_time) if dc_creation_time.is_a?(String)
      history = history(project_name)
      history.each do |build|start
        return build if build.dc_creation_time == dc_creation_time
      end
      nil
    end    

    def register(build)
      history = history(build.project_name)
      if(history.empty?)
        @history[build.project_name] = history
      end
      history << build unless history.index(build)
      if(@project_directories)
        dump(history, build.project_name)
      end
    end
    
    def project_names
      @history.keys.sort
    end
    
    def search(regexp, required_project_name=nil)
      result = []
      project_names.each do |project_name|
        if(required_project_name == project_name || required_project_name.nil?)
          history = history(project_name)
          history.each do |build|
            result << build if build =~ regexp
          end
        end
      end
      result
    end

    def next(build)
      return nil unless build
      h = history(build.project_name)
      i = h.index(build)
      return h[i + 1] unless i == h.length - 1
    end

    def prev(build)
      return nil unless build
      h = history(build.project_name)
      i = h.index(build)
      return h[i - 1] unless i == 0
    end

    def previous_successful_build(build)
      history = history(build.project_name)
      return nil unless history
      idx = history.index(build)
      history[0..idx].reverse.find do |a_build| 
        a_build.status == Build::SUCCESSFUL && a_build != build
      end
    end

    def to_rss(project_name, html_url)
      rss = REXML::Document.new
      rss.add_element("rss")
      rss.root.add_attribute("version", "2.0")
      channel = rss.root.add_element("channel")
      channel.add_element("title").add_text("DamageControl: #{project_name}")
      channel.add_element("description").add_text("Build results for #{project_name}")
      channel.add_element("link").add_text(html_url)
      history(project_name).reverse.each do |build|
        if build.completed?
          channel.add(build.to_rss_item)
        end
      end
      rss
    end

    # should ideally be private, but need access when upgrading formats
    def dump(history, project_name)
      # safe writing of history file
      file = history_file(project_name)
      writing_file = "#{file}.writing"
      old_file = "#{file}.old"
      # writing on temporary file: prepare
      File.open(writing_file, "w") do |io|
        YAML::dump(history, io)
      end
      # move away old file as backup
      File.delete(old_file) if File.exist?(old_file)
      File.move(file, old_file) if File.exist?(file)
      # rename = semi-atomic operation: commit!
      File.move(writing_file, file)
    end

  private

    def populate_cache_from_files
      @project_directories.project_names.each do |project_name|
        builds = load(project_name)
        @history[project_name] = builds unless builds.nil?
      end
    end

    def load(project_name)
      builds = nil
      filename = history_file(project_name)
			logger.info("Loading project #{project_name} with history #{filename}")
      if(File.exist?(filename))
        file = File.new(filename)
        begin
          yaml = file.read
          builds = YAML::load(yaml)
          file.close
          verify(builds)
        rescue Exception => e
          begin
            file.close
          rescue
          end
          upgrade_to_new_and_store_old(filename)
					backupfile = "#{filename}.old"
					if (File.exists?(backupfile))
						logger.info("Using backupfile #{backupfile} instead")
						File.rename(backupfile, filename)
						builds = load(project_name)
					else
          	builds = []
					end
        end
      end
      builds
    end
    
    def verify(builds)
      builds.each do |build|
        raise "Not a Build: #{build}" unless build.is_a?(Build)
        raise "ChangeSets not initialised" unless build.changesets
        build.changesets.each do |changeset|
          raise "Not a ChangeSet: #{changeset}" unless changeset.is_a?(ChangeSet)
          changeset.each do |change|
            raise "Not a Change: #{change}" unless change.is_a?(Change)
          end
        end
      end
    end

    def upgrade_to_new_and_store_old(filename)
      backup = "#{filename}.#{Time.now.utc.to_i}.backup"
      logger.error("#{filename} can't be parsed. might be of an older format")
      logger.error("Copying it over to #{backup}")
      File.move(filename, backup)
    end

    def history_file(project_name)
      File.expand_path(@project_directories.build_history_file(project_name))
    end
        
  end
end
