require 'pebbles/Pathutils'
require 'pebbles/LineEditor'
require 'pebbles/Process'
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

    def checkout(checkout_dir, scm_to_time, &line_proc)
      mkdir_p(checkout_dir)
      checked_out_files = []
      path_regex = /^[A|D|U]\s*(.*)/
      if(checked_out?(checkout_dir))
        svn(checkout_dir, update_command(scm_to_time)) do |line|
          if(line =~ path_regex)
            checked_out_files << $1
          end
          line_proc.call(line) if block_given?
        end
      else
        svn(checkout_dir, checkout_command(scm_to_time)) do |line|
          if(line =~ path_regex)
            checked_out_files << $1
          end
          line_proc.call(line) if block_given?
        end
      end
      checked_out_files
    end

    def uptodate?(checkout_dir, start_time, end_time)
      if(!checked_out?(checkout_dir))
        # might as well check it out if it isn't checked out
        # TODO: is this the right place to do that? prolly not.
        checkout(checkout_dir, end_time)
        false
      else
        local_revision(checkout_dir) == head_revision(checkout_dir)
      end
    end

    def local_revision(checkout_dir)
      local_revision = nil
      svn(checkout_dir, "info") do |line|
        if(line =~ /Revision: ([0-9]*)/)
          return $1.to_i
        end
      end
    end

    def head_revision(checkout_dir)
      cmd = "svn log #{repourl} -r HEAD"
      logger.info(cmd)
      cmd_with_io(checkout_dir, cmd) do |io|
        parser = SVNLogParser.new(io, svnpath)
        changesets = parser.parse_changesets
        changesets[0].revision.to_i
      end
    end

    def commit(checkout_dir, message, &line_proc)
      svn(checkout_dir, commit_command(message), &line_proc)
    end

    def label(checkout_dir)
      local_revision(checkout_dir).to_s
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
      mkdir_p(nativepath_to_filepath(native_path))
      svnadmin(svnrootdir, "create #{native_path}", &line_proc)
    end

    def install_trigger(trigger_command, damagecontrol_install_dir, &proc)
      if (windows?)
        install_win_trigger(trigger_command, damagecontrol_install_dir, &proc)
      else
        install_unix_trigger(trigger_command, damagecontrol_install_dir, &proc)
      end
    end
    
    def install_unix_trigger(trigger_command, damagecontrol_install_dir, &proc)
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
    
    def install_win_trigger(trigger_command, damagecontrol_install_dir, &proc)
      post_commit_exists = File.exists?(post_commit_file)
      mode = post_commit_exists ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      File.open(post_commit_file, mode) do |file|
        file.puts("#{trigger_command}\n" )
      end
    end
    
    def uninstall_trigger(trigger_command, trigger_files_checkout_dir)
      File.comment_out(post_commit_file, /#{Regexp.escape(trigger_command)}/, nil)
    end
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
      return false unless File.exist?(post_commit_file)
      not_already_commented = comment_out(File.new(post_commit_file), /#{Regexp.escape(trigger_command)}/, "# ", "")
      not_already_commented
    end
    
    def import(dir, &line_proc)
      import_cmd = "import #{svnurl} -m \"initial import\""
      svn(dir, import_cmd, &line_proc)
    end

    def changesets(checkout_dir, scm_from_time, scm_to_time, files, &line_proc)
      changesets = nil

      command = "svn #{changes_command(scm_from_time, scm_to_time, files)}"
      yield command if block_given?

      cmd_with_io(checkout_dir, command) do |stdout|
        parser = SVNLogParser.new(stdout, svnpath)
        changesets = parser.parse_changesets(scm_from_time, scm_to_time, &line_proc)
      end
      changesets
    end
    
    # url pointing to the root of the repo
    def repourl
      last = (svnpath.nil? || svnpath == "") ? -1 : -(svnpath.length)-2
      svnurl[0..last]
    end

  private

    def svnrootdir
      last = (svnpath.nil? || svnpath == "") ? -1 : -(svnpath.length)-2
      result = svnurl["file://".length..last]
      # for windows, turn /c:/blabla into c:/blabla"
      if(result =~ /^\/[a-zA-Z]:/)
        result = result[1..-1]
      end
      result
    end

    def svn(dir, cmd, &line_proc)
      command_line = "svn #{cmd}"

      # not specifying stderr - cmd_with_io will read it in a separate thread.
      cmd_with_io(dir, command_line) do |stdout|
        begin
          logger.info("Reading stdout")
          stdout.each_line do |progress|
            if block_given? then yield progress else logger.debug(progress) end
          end
        end
      end
    end

    def svnadmin(dir, cmd, &line_proc)
      command_line = "svnadmin #{cmd}"

      # not specifying stderr - cmd_with_io will read it in a separate thread.
      cmd_with_io(dir, command_line) do |stdout|
        stdout.each_line do |progress|
            if block_given? then yield progress else logger.debug(progress) end
        end
      end
    end
    
    def checked_out?(checkout_dir)
      rootentries = File.expand_path("#{checkout_dir}/.svn/entries")
      File.exists?(rootentries)
    end

    def checkout_command(scm_to_time)
      "checkout #{revision_option(nil, scm_to_time)} #{svnurl} ."
    end

    def update_command(scm_to_time)
      "update  #{revision_option(nil, scm_to_time)}"
    end
    
    def changes_command(scm_from_time, scm_to_time, files)
      # http://svnbook.red-bean.com/svnbook-1.1/svn-book.html#svn-ch-3-sect-3.3
      # file_list = files.join('\n')
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
      time.utc.strftime("%Y-%m-%d %H:%M:%S +0000")
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
      FileUtils::windows? ? "#{svnrootdir}/hooks/post-commit.cmd" : "#{svnrootdir}/hooks/post-commit"
    end
    
  end
end
