require 'pebbles/Pathutils'
require 'pebbles/LineEditor'
require 'pebbles/AsyncProcess'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/SVNLogParser'
require 'damagecontrol/util/FileUtils'

module DamageControl

  class SVN < AbstractSCM
    include FileUtils
    include Pebbles
    include Pebbles::Pathutils
    include Pebbles::LineEditor
    
    attr_accessor :svnurl
    attr_accessor :svnpath

    # set to true if the local svn binaries (for trigger installation) is native windows
    # triggers don't work with cygwin svn (svn bug)
    attr_accessor :native_windows

    def name
      "Subversion"
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

    def checkout(checkout_dir, scm_from_time, scm_to_time, &line_proc)
      mkdir_p(checkout_dir)
      checked_out_files = []
      path_regex = /^[A|D|U]\s*(.*)/
      if(checked_out?(checkout_dir))
        svn(checkout_dir, update_command(scm_from_time, scm_to_time)) do |line|
          if(line =~ path_regex)
            checked_out_files << $1
          end
          line_proc.call(line) if block_given?
        end
        changesets(checkout_dir, scm_from_time, scm_to_time, checked_out_files, &line_proc)
      else
        svn(checkout_dir, checkout_command(scm_from_time, scm_to_time)) do |line|
          if(line =~ path_regex)
            checked_out_files << $1
          end
          line_proc.call(line) if block_given?
        end
        # See comment in AbstractSCM.checkout
          most_recent_timestamp(changesets(checkout_dir, scm_from_time, scm_to_time, checked_out_files, &line_proc))
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

    def can_create?
      local?
    end

    def exists?
      if(local?)
        File.exists?("#{svnrootdir}/db")
      else
        # don't know. assume yes.
        false
      end
    end

    def supports_trigger?
      local?
    end

    def create(&line_proc)      
      native_path = filepath_to_nativepath(svnrootdir, true)
      mkdir_p(native_path)
      svnadmin(svnrootdir, "create #{native_path}", &line_proc)
    end

    def install_trigger(trigger_command, damagecontrol_install_dir, &proc)
      post_commit_exists = File.exists?(post_commit_file)
      mode = post_commit_exists ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      begin
        File.open(post_commit_file, mode) do |file|
          file.puts("#!/bin/sh") unless post_commit_exists 
          file.puts("#{trigger_command}\n" )
        end
        system("chmod g+x #{post_commit_file}")
      rescue
        raise "Didn't have persmissions to write to #{post_commit_file}. " +
        "Try to manually add the following line:\n\n#{trigger_command}\n\n" +
        "Finally make it executable with chmod g+x #{post_commit_file}\n\n"
      end
    end
    
    def uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      File.comment_out(post_commit_file, /#{trigger_command}/, "# ")
    end
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
      return false unless File.exist?(post_commit_file)
      in_post_commit = comment_out(File.new(post_commit_file), /#{trigger_command}/, "# ", "")
      in_post_commit
    end
    
    def import(dir, &line_proc)
      import_cmd = "import #{svnurl} -m \"initial import\""
      svn(dir, import_cmd, &line_proc)
    end

  private
    def svnrootdir
      last = svnpath.nil? ? -1 : -(svnpath.length)-2
      result = svnurl["file://".length..last]
      # for windows, turn /c:/blabla into c:/blabla"
      if(result =~ /^\/[a-zA-Z]:/)
        result = result[1..-1]
      end
      result
    end

    def changesets(checkout_dir, scm_from_time, scm_to_time, files, &line_proc)
      changesets = nil

      command = "svn #{changes_command(scm_from_time, scm_to_time, files)}"
      yield command if block_given?

      execute(command, checkout_dir) do |stdin, stdout, stderr, pid|
        logger.debug("Reading log from stdout")
        parser = SVNLogParser.new(stdout, svnpath)
        changesets = parser.parse_changesets(scm_from_time, scm_to_time, &line_proc)
        logger.debug("DONE Reading log from stdout")
      end
      changesets
    end

    def svn(dir, cmd, &line_proc)
      command_line = "svn #{cmd}"

      execute(command_line, dir) do |stdin, stdout, stderr, pid|
        begin
          logger.debug("Reading stdout")
          stdout.each_line do |progress|
              if block_given? then yield progress else logger.debug(progress) end
          end
          logger.info("DONE Reading stdout")
        ensure
          logger.debug("Reading stderr")
          stderr.each_line do |progress|
              if block_given? then yield progress else logger.debug(progress) end
          end
          logger.info("DONE Reading stderr")
        end
      end
    end

    def svnadmin(dir, cmd, &line_proc)
      command_line = "svnadmin #{cmd}"

      execute(command_line, dir) do |stdin, stdout, stderr, pid|
        stdout.each_line do |progress|
            if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end
    
    def checked_out?(checkout_dir)
      rootentries = File.expand_path("#{checkout_dir}/.svn/entries")
      File.exists?(rootentries)
    end

    def checkout_command(scm_from_time, scm_to_time)
      "checkout #{svnurl} ."
    end

    def update_command(scm_from_time, scm_to_time)
      "update"
    end
    
    def changes_command(scm_from_time, scm_to_time, files)
      # http://svnbook.red-bean.com/svnbook-1.1/svn-book.html#svn-ch-3-sect-3.3
      file_list = files.join('\n')
# WEIRD cygwin bug garbles this!?!?!?!
      "log --verbose #{revision_option(scm_from_time, scm_to_time)}"
    end

    def revision_option(scm_from_time, scm_to_time)
      from = svndate(scm_from_time)
      to = svndate(scm_to_time)
      revision_option = nil
      if(from && to.nil?)
        revision_option = "--revision {\"#{from}\"}:HEAD"
      elsif(from.nil? && to)
        revision_option = "--revision {\"#{to}\"}"
      elsif(from.nil? && to.nil?)
        revision_option = ""
      elsif(from && to)
        revision_option = "--revision {\"#{from}\"}:{\"#{to}\"}"
      end
      revision_option
    end
    
    def svndate(time)
      return nil unless time
      time.utc.strftime("%Y-%m-%d %H:%M:%S")
    end

    def commit_command(message)
      "commit -m \"#{message}\""
    end
    
    def local?
      if(svnurl =~ /^file:/)
        return true
      else
        return false
      end
    end

    def post_commit_file
      # We actualy need to use the .cmd when on cygwin. The cygwin svn post-commit
      # hook is hosed. We'll be relying on native windows
      native_windows ? "#{svnrootdir}/hooks/post-commit.cmd" : "#{svnrootdir}/hooks/post-commit"
    end
    
  end
end
