require 'stringio'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/SVNLogParser'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class SVN < AbstractSCM
    include FileUtils
    
    attr_accessor :svnurl
    attr_accessor :svnprefix

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

      parser = SVNLogParser.new(StringIO.new(log), svnprefix)
      parser.parse_changesets
    end

    def working_dir
      "#{checkout_dir}/#{svnprefix}"
    end

  private
  
    def checked_out?
      false
    end

    def checkout_command(time)
      "checkout #{svnurl}"
    end

    def update_command(time)
      "-d#{svnroot} update -d -P"
    end
    
    def commit_command(message)
      "commit -m \"#{message}\""
    end
    
    def changes_command(from_time, to_time)
#      "log -v -r {\"#{svndate(from_time)}\"}:{\"#{svndate(to_time)}\"} #{svnurl}"
      "log -v -r HEAD #{svnurl}"
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
    attr_accessor :svnrootdir
    attr_accessor :project_url
  
    def initialize(basedir, svnprefix)
      self.svnrootdir = "#{basedir}/svnroot"
      hack = "/" if windows?
      hack = "" unless hack
      self.svnurl = "file://#{hack}#{svnrootdir}/#{svnprefix}"
      self.svnprefix = svnprefix
      self.checkout_dir = "#{basedir}/checkout"
    end

    def create
      svnadmin(svnrootdir, "create #{svnrootdir}")
    end

    def import(dir)
      basename = File.basename(dir)
      svn(dir, "import #{dir} #{svnurl} -m \"initial import\"")
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
    
    def post_commit_file
      if windows? then "#{svnrootdir}/hooks/post-commit.bat" else "#{svnrootdir}/hooks/post-commit" end
    end
    
    def install_trigger(damagecontrol_install_dir, project_name, dc_url="http://localhost:4712/private/xmlrpc", &proc)
      # this stuff doesn't work for some reason, if you execute the file manually it works, but svn never executes the post-commit trigger
      File.open("#{post_commit_file}", "w") do |file|
        trigger_command = trigger_command(damagecontrol_install_dir, project_name, dc_url)
        file.puts("#!/bin/sh") unless windows?
        file.puts(trigger_command)
      end
      system("chmod g+x #{post_commit_file}") unless windows?
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
