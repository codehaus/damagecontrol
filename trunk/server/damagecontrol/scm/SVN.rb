require 'pebbles/Pathutils'
require 'pebbles/LineEditor'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/SVNLogParser'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class SVN < AbstractSCM
    include FileUtils
    include Pebbles::Pathutils
    include Pebbles::LineEditor
    
    attr_accessor :svnurl
    attr_accessor :svnpath

    def checkout(time = nil, &line_proc)
      if(checked_out?)
        svn(working_dir, update_command(time), &line_proc)
      else
        svn(checkout_dir, checkout_command(time), &line_proc)
      end
    end

    def commit(message, &line_proc)
      svn(working_dir, commit_command(message), &line_proc)
    end

    def changesets(from_time, to_time, &line_proc)
      command = changes_command(from_time, to_time)
      yield command if block_given?

      cmd_with_io(working_dir, "svn #{command}") do |io|
        parser = SVNLogParser.new(io, svnpath)
        parser.parse_changesets(&line_proc)
      end

    end

    def working_dir
      "#{checkout_dir}/#{svnpath}"
    end
    
  private
  
    def svn(dir, cmd, &line_proc)
      command_line = "svn #{cmd}"
      yield command_line if block_given?
      cmd_with_io(dir, command_line) { |io|
        io.each_line { |line|
          yield line if block_given?
        }
      }
    end

    def svnadmin(dir, cmd, &line_proc)
      command_line = "svnadmin #{cmd}"
      yield command_line if block_given?
      cmd_with_io(dir, command_line) { |io|
        io.each_line { |line|
          yield line if block_given?
        }
      }
    end
    
    def checked_out?
      rootentries = File.expand_path("#{working_dir}/.svn/entries")
      File.exists?(rootentries)
    end

    def checkout_command(time)
      "checkout #{svnurl}"
    end

    def update_command(time)
      "update"
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
    # set to true if the local svn binaries (for trigger installation) is native windows
    # triggers don't work with cygwin svn (svn bug)
    attr_accessor :native_windows
  
    def initialize(basedir, svnpath)
      self.svnrootdir = "#{basedir}/svnroot"
      self.svnurl = "#{filepath_to_nativeurl(svnrootdir)}/#{svnpath}"
      self.svnpath = svnpath
      self.checkout_dir = "#{basedir}/checkout"
    end

    def create(&line_proc)
      native_path = filepath_to_nativepath(svnrootdir, true)
puts "#########################################################"
puts native_path
puts "GRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR"
      svnadmin(svnrootdir, "create #{native_path}", &line_proc)
    end

    def import(dir, &line_proc)
      basename = File.basename(dir)
      cmd = "import #{filepath_to_nativepath(dir, true)} #{svnurl} -m \"initial import\""
      svn(dir, cmd, &line_proc)
    end

    def can_install_trigger?
      true
    end

    def install_trigger(damagecontrol_install_dir, project_name, dc_url="http://localhost:4712/private/xmlrpc", &proc)
      mode = File.exists?(post_commit_file) ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      File.open(post_commit_file, mode) do |file|
        trigger_command = trigger_command(damagecontrol_install_dir, project_name, dc_url)
        file.puts("#!/bin/sh")
        file.puts(trigger_command)
      end
      system("chmod g+x #{post_commit_file}")
    end
    
    def uninstall_trigger(project_name)
      File.uncomment(post_commit_file, /#{project_name}/, "# ")
    end
    
    def trigger_installed?(project_name)
      return false unless File.exist?(post_commit_file)
      # This is not exatly accurate, but it will do for  now
      post_commit_contents = File.new(post_commit_file).read
      Regexp.new("^[^# ].*--projectname #{project_name}") =~ post_commit_contents ? true : false
    end
    
    def add_file(relative_filename, content, is_new)
      with_working_dir(working_dir) do
        File.mkpath(File.dirname(relative_filename))
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end

        if(is_new)
          svn(working_dir, "add #{relative_filename}", &line_proc)
        end

        commit("adding #{relative_filename}", &line_proc)
      end
    end
    
    # TODO: refactor. This is ugly! Should go to the generic tests
    def add_or_edit_and_commit_file(relative_filename, content, &line_proc)
      existed = false
      with_working_dir(working_dir) do
        File.mkpath(File.dirname(relative_filename))
        existed = File.exist?(relative_filename)
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end
      end
      svn(working_dir, "add #{relative_filename}", &line_proc) unless(existed)

      message = existed ? "editing" : "adding"

      commit("#{message} #{relative_filename}", &line_proc)
    end

  private

    def post_commit_file
      # We actualy need to use the .cmd when on cygwin. The cygwin svn post-commit
      # hook is hosed. We'll be relying on native windows
      native_windows ? "#{svnrootdir}/hooks/post-commit.cmd" : "#{svnrootdir}/hooks/post-commit"
    end
    
  end
end
