require 'stringio'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/SVNLogParser'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class SVN < AbstractSCM
    include FileUtils

    def initialize(config_map)
      super(config_map)
      @svnurl = config_map["svnurl"] || required_config_param("svnurl", config_map)
      @svnprefix = config_map["svnprefix"] || required_config_param("svnprefix", config_map)
    end
  
    def web_url_to_change(change)
      view_cvs_url = config_map["view_cvs_url"]
      return super if view_cvs_url.nil? || view_cvs_url == "" 

      view_cvs_url_patched = ensure_trailing_slash(view_cvs_url)
      url = "#{view_cvs_url_patched}#{change.path}"
      url << "?r1=#{change.previous_revision}&r2=#{change.revision}" if(change.previous_revision)
      url
    end

    def checkout(time = nil, &proc)
      if(checked_out?)
        svn(working_dir, update_command(time), &proc)
      else
        svn(checkout_dir, checkout_command(time), &proc)
      end
    end

    def commit(message, &proc)
      svn(working_dir, commit_command(message), &proc)
    end

    def changesets(from_time, to_time)
      log = ""
      command = changes_command(from_time, to_time)
      yield command if block_given?
      svn(working_dir, command) do |io|
        io.each_line do |line|
          log << line
          yield line if block_given?
        end
      end

      parser = SVNLogParser.new(StringIO.new(log), @svnprefix)
      parser.parse_changesets
    end

    def working_dir
      "#{checkout_dir}/#{@svnprefix}"
    end

  private
  
    def checked_out?
      false
    end

    def checkout_command(time)
      "checkout #{@svnurl}"
    end

    def update_command(time)
      "-d#{@cvsroot} update -d -P"
    end
    
    def commit_command(message)
      "commit -m \"#{message}\""
    end
    
    def changes_command(from_time, to_time)
#      "log -v -r {\"#{svndate(from_time)}\"}:{\"#{svndate(to_time)}\"} #{@svnurl}"
      "log -v -r HEAD #{@svnurl}"
    end

    def svndate(time)
      time.utc.strftime("%Y-%m-%d %H:%M:%S")
    end

    def svn(dir, cmd, &proc)
      cmd(dir, "svn #{cmd}", &proc)
    end

    def svnadmin(dir, cmd, &proc)
      cmd(dir, "svnadmin #{cmd}", &proc)
    end
    
    def install_trigger(*args)
      raise "can't automatically install trigger for Subversion, you need to install it manually"
    end
  end

  ##################################################################################
  # This is only used during testing
  ##################################################################################

  class LocalSVN < SVN
    def initialize(basedir, svnprefix)
      @svnrootdir = "#{basedir}/svnroot"
      hack = "/" if windows?
      hack = "" unless hack
      @repo_url = "file://#{hack}#{@svnrootdir}"
      @project_url = "#{@repo_url}/#{svnprefix}"
      super("svnurl" => @project_url, "svnprefix" => svnprefix, "checkout_dir" => "#{basedir}/checkout")
      @svnprefix = svnprefix
    end

    def create
      svnadmin(@svnrootdir, "create #{@svnrootdir}")
    end

    def import(dir)
      basename = File.basename(dir)
      svn(dir, "import #{dir} #{@svnurl} -m \"initial import\"")
    end

    def add_file(relative_filename, content, is_new)
      with_working_dir(working_dir) do
        File.mkpath(File.dirname(relative_filename))
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end

        if(is_new)
          svn(working_dir, "add #{relative_filename}")
        end

        commit("adding #{relative_filename}")
      end
    end
    
    def hookdir
      "#{@svnrootdir}/hooks"
    end
    
    def trigger_command(project_name, dc_url)
      "#{ruby_path} #{trigger_script_name} #{dc_url} #{project_name}"
    end
    
    def hook_file
      if windows? then "post-commit.bat" else "post-commit" end
    end
    
    def install_trigger(project_name, dc_url)
      # this stuff doesn't work for some reason, if you execute the file manually it works, but svn never executes the post-commit trigger
      File.open("#{hookdir}/#{hook_file}", "w") do |file|
        trigger_command = trigger_command(project_name, dc_url)
        file.puts("#!/bin/sh") unless windows?
        file.puts(trigger_command)
      end
      system("chmod a+x #{hookdir}/#{hook_file}") unless windows?
      File.open("#{hookdir}/#{trigger_script_name}", "w") do |io|
        io.puts(trigger_script)
      end
    end
    
    # TODO: refactor. This is ugly!
    def add_or_edit_and_commit_file(relative_filename, content)
      existed = false
      with_working_dir(working_dir) do
        File.mkpath(File.dirname(relative_filename))
        existed = File.exist?(relative_filename)
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end
      end
      svn(working_dir, "add #{relative_filename}") unless(existed)

      message = existed ? "editing" : "adding"

      commit("#{message} #{relative_filename}")
    end
  end
end
