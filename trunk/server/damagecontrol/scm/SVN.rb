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

    def checkout(checkout_dir, time = nil, &line_proc)
      if(checked_out?(checkout_dir))
        svn(checkout_dir, update_command(time), &line_proc)
      else
        svn(checkout_dir, checkout_command(checkout_dir), &line_proc)
      end
    end

    def commit(checkout_dir, message, &line_proc)
      svn(checkout_dir, commit_command(message), &line_proc)
    end

    def label(checkout_dir, &line_proc)
      revision = nil
      svn(checkout_dir, "status --show-updates") do |io|
        io.each_line { |line|
          if(line =~ /([0-9])/)
            revision = $1
          end
        }
      end
      revision
    end

    def changesets(checkout_dir, from_time, to_time, &line_proc)
      command = changes_command(from_time, to_time)
      yield command if block_given?

      cmd_with_io(checkout_dir, "svn #{command}") do |io|
        parser = SVNLogParser.new(io, svnpath)
        parser.parse_changesets(&line_proc)
      end

    end

    def uptodate?(checkout_dir, start_time, end_time)
      if(!checked_out?(checkout_dir))
        # might as well check it out if it isn't checked out
        checkout(checkout_dir)
        false
      end

      uptodate = true
      svn(checkout_dir, "status --show-updates") do |io|
        io.each_line { |line|
          if(line =~ /\*/)
            # we get stars if we're not uptodate
            uptodate = false
          end
        }
      end
      uptodate
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
    
    def checked_out?(checkout_dir)
      rootentries = File.expand_path("#{checkout_dir}/.svn/entries")
      File.exists?(rootentries)
    end

    def checkout_command(checkout_dir)
      native_checkout_dir = filepath_to_nativepath(checkout_dir, true)
      "checkout #{svnurl} ."
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
    end

    def create(&line_proc)
      native_path = filepath_to_nativepath(svnrootdir, true)
      svnadmin(svnrootdir, "create #{native_path}", &line_proc)
    end

    def import(dir, &line_proc)
      cmd = "import #{filepath_to_nativepath(dir, true)} #{svnurl} -m \"initial import\""
      svn(dir, cmd, &line_proc)
    end

    def can_install_trigger?
      true
    end

    def install_trigger(damagecontrol_install_dir, project_name, trigger_files_checkout_dir, dc_url="http://localhost:4712/private/xmlrpc", &proc)
      mode = File.exists?(post_commit_file) ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      File.open(post_commit_file, mode) do |file|
        trigger_command = trigger_command(damagecontrol_install_dir, project_name, dc_url)
        file.puts("#!/bin/sh")
        file.puts(trigger_command)
      end
      system("chmod g+x #{post_commit_file}")
    end
    
    def uninstall_trigger(trigger_files_checkout_dir, project_name)
      File.uncomment(post_commit_file, /#{project_name}/, "# ")
    end
    
    def trigger_installed?(trigger_files_checkout_dir, project_name)
      return false unless File.exist?(post_commit_file)
      # This is not exatly accurate, but it will do for  now
      post_commit_contents = File.new(post_commit_file).read
      Regexp.new("^[^# ].*--projectname #{project_name}") =~ post_commit_contents ? true : false
    end
    
    def add_file(relative_filename, content, is_new)
      with_checkout_dir(checkout_dir) do
        File.mkpath(File.dirname(relative_filename))
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end

        if(is_new)
          svn(checkout_dir, "add #{relative_filename}", &line_proc)
        end

        commit("adding #{relative_filename}", &line_proc)
      end
    end
    
    # TODO: refactor. This is ugly! Should go to the generic tests
    def add_or_edit_and_commit_file(checkout_dir, relative_filename, content, &line_proc)
      existed = false
      with_working_dir(checkout_dir) do
        File.mkpath(File.dirname(relative_filename))
        existed = File.exist?(relative_filename)
        File.open(relative_filename, "w") do |file|
          file.puts(content)
        end
      end
      svn(checkout_dir, "add #{relative_filename}", &line_proc) unless(existed)

      message = existed ? "editing" : "adding"

      commit(checkout_dir, "#{message} #{relative_filename}", &line_proc)
    end

  private

    def post_commit_file
      # We actualy need to use the .cmd when on cygwin. The cygwin svn post-commit
      # hook is hosed. We'll be relying on native windows
      native_windows ? "#{svnrootdir}/hooks/post-commit.cmd" : "#{svnrootdir}/hooks/post-commit"
    end
    
  end
end
