require 'cgi'
require 'yaml'
require 'rexml/document'
require 'damagecontrol/core/Build'
require 'damagecontrol/core/BuildSerializer'
require 'damagecontrol/util/Logging'
require 'damagecontrol/util/FileUtils'
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

    def initialize(channel, basedir, html_url=nil)
      super
      channel.add_consumer(self)
      @basedir = basedir
      @html_url = html_url
      @build_serializer = BuildSerializer.new
    end
    
    def on_message(message)
      if message.is_a?(BuildEvent) && !message.is_a?(BuildProgressEvent)
        register(message.build)
      end
    end
    
    # TODO rename to dump (more aligned with YAML terminology - we're doing a similar thing)
    def register(build)
      @build_serializer.dump(build, build_dir(build.project_name, build.dc_creation_time))
      write_rss(build.project_name)
    end
    
    def project_names
      Dir["#{@basedir}/*"].collect do |filename|
        File.basename(filename)
      end.sort
    end
    
    def history(project_name, with_changesets=false)
      build_dirs(project_name).collect do |build_dir|
        @build_serializer.load(build_dir, with_changesets)
      end
    end

    def lookup(project_name, dc_creation_time, with_changesets=false)
      @build_serializer.load(build_dir(project_name, dc_creation_time), with_changesets)
    end    

    def current_build(project_name, with_changesets=false)
      build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, with_changesets)
        return build unless build.status == Build::QUEUED
      end
      nil
    end
    
    def last_completed_build(project_name, with_changesets=false)
      build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, with_changesets)
        return build if build.completed?
      end
      nil
    end
    
    def last_successful_build(project_name, with_changesets=false)
      build_dirs(project_name).reverse.each do |build_dir|
        build = @build_serializer.load(build_dir, with_changesets)
        return build if build.successful?
      end
      nil
    end
    
    def next(build, with_changesets=false)
      return nil unless build
      build_dirs(build.project_name).each do |build_dir|
        b = @build_serializer.load(build_dir, with_changesets)
        return b if b.dc_creation_time > build.dc_creation_time
      end
      nil
    end

    def prev(build, with_changesets=false)
      return nil unless build
      build_dirs(build.project_name).reverse.each do |build_dir|
        b = @build_serializer.load(build_dir, with_changesets)
        return b if b.dc_creation_time < build.dc_creation_time
      end
      nil
    end

    def to_rss(project_name)
      File.new(rss_file(project_name)).read
    end
    
#### Files and directories ####
    
    def checkout_dir(project_name)
      "#{project_dir(project_name)}/checkout"
    end

    def stdout_file(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/stdout.log"
    end

    def stderr_file(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/stderr.log"
    end

    def xml_log_file(project_name, dc_creation_time)
      "#{build_dir(project_name, dc_creation_time)}/log.xml"
    end

  private
  
    # writes rss to disk
    def write_rss(project_name)
      rss = REXML::Document.new
      rss.add_element("rss")
      rss.root.add_attribute("version", "2.0")
      channel = rss.root.add_element("channel")
      channel.add_element("title").add_text("DamageControl: #{project_name}")
      channel.add_element("description").add_text("Build results for #{project_name}")
      channel.add_element("link").add_text("#{@html_url}#{CGI.escape(project_name)}")
      history(project_name).reverse.each do |build|
        channel.add(build.to_rss_item)
      end

      File.open(rss_file(project_name), "w") do |io|
        io.puts(rss.to_s)
      end
    end

    def project_dir(project_name)
      "#{@basedir}/#{project_name}"
    end

    def builds_dir(project_name)
      "#{project_dir(project_name)}/build"
    end

    def build_dirs(project_name)
      Dir["#{builds_dir(project_name)}/[0-9]*"].sort
    end

    def build_dir(project_name, dc_creation_time)
      "#{builds_dir(project_name)}/#{dc_creation_time.ymdHMS}"
    end

    def rss_file(project_name)
      "#{builds_dir(project_name)}/rss.xml"
    end

  end
end
