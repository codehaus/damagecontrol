require 'rscm/path_converter'
require 'rscm/line_editor'
require 'rscm/abstract_scm'
require 'rscm/svn/svn_log_parser'

module RSCM

  # RSCM implementation for Subversion.
  #
  # You need the svn/svnadmin executable on the PATH in order for it to work.
  #
  # NOTE: On Cygwin these have to be the win32 builds of svn/svnadmin and not the Cygwin ones.
  class SVN < AbstractSCM
    include FileUtils
    include PathConverter
    
    attr_accessor :svnurl
    attr_accessor :svnpath

    def initialize(svnurl=nil, svnpath="")
      @svnurl, @svnpath = svnurl, svnpath
    end

    def name
      "Subversion"
    end

    def add(checkout_dir, relative_filename)
      svn(checkout_dir, "add #{relative_filename}")
    end

    def checkout(checkout_dir, to_identifier=Time.infinity, &line_proc)
      checkout_dir = PathConverter.filepath_to_nativepath(checkout_dir, false)
      mkdir_p(checkout_dir)
      checked_out_files = []
      path_regex = /^[A|D|U]\s+(.*)/
      if(checked_out?(checkout_dir))
        svn(checkout_dir, update_command(to_identifier)) do |line|
          if(line =~ path_regex)
            absolute_path = "#{checkout_dir}/#{$1}"
            relative_path = $1.chomp
            relative_path = relative_path.gsub(/\\/, "/") if WINDOWS
            checked_out_files << relative_path
          end
          line_proc.call(line) if block_given?
        end
      else
        svn(checkout_dir, checkout_command(to_identifier, checkout_dir)) do |line|
          if(line =~ path_regex)
            native_absolute_path = $1
            native_checkout_dir = $1
            absolute_path = PathConverter.nativepath_to_filepath($1)
            native_checkout_dir = PathConverter.filepath_to_nativepath(checkout_dir, false)
            if(File.exist?(absolute_path) && !File.directory?(absolute_path))
              relative_path = native_absolute_path[native_checkout_dir.length+1..-1].chomp
              relative_path = relative_path.gsub(/\\/, "/") if WINDOWS
              checked_out_files << relative_path
            end
          end
          line_proc.call(line) if block_given?
        end
      end
      checked_out_files.sort!
    end

    def checkout_commandline(to_identifier=Time.infinity)
      "svn checkout #{revision_option(nil, to_identifier)}"
    end

    def update_commandline(to_identifier=Time.infinity)
      "svn update #{revision_option(nil, to_identifier)} #{svnurl} #{checkout_dir}"
    end

    def uptodate?(checkout_dir)
      if(!checked_out?(checkout_dir))
        false
      else
        lr = local_revision(checkout_dir)
        hr = head_revision(checkout_dir)
        lr == hr
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
      with_working_dir(checkout_dir) do
        IO.popen(cmd) do |stdout|
          parser = SVNLogParser.new(stdout, svnpath, checkout_dir)
          changesets = parser.parse_changesets
          changesets[0].revision.to_i
        end
      end
    end

    def commit(checkout_dir, message, &line_proc)
      svn(checkout_dir, commit_command(message), &line_proc)
      # We have to do an update to get the local revision right
      svn(checkout_dir, "update", &line_proc)
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
      native_path = PathConverter.filepath_to_nativepath(svnrootdir, true)
      mkdir_p(PathConverter.nativepath_to_filepath(native_path))
      svnadmin(svnrootdir, "create #{native_path}", &line_proc)
    end

    def install_trigger(trigger_command, damagecontrol_install_dir, &line_proc)
      if (WINDOWS)
        install_win_trigger(trigger_command, damagecontrol_install_dir, &line_proc)
      else
        install_unix_trigger(trigger_command, damagecontrol_install_dir, &line_proc)
      end
    end
    
    def uninstall_trigger(trigger_command, trigger_files_checkout_dir, &line_proc)
      File.comment_out(post_commit_file, /#{Regexp.escape(trigger_command)}/, nil)
    end
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir)
      return false unless File.exist?(post_commit_file)
      not_already_commented = LineEditor.comment_out(File.new(post_commit_file), /#{Regexp.escape(trigger_command)}/, "# ", "")
      not_already_commented
    end
    
    def import(dir, message, &line_proc)
      import_cmd = "import #{svnurl} -m \"#{message}\""
      svn(dir, import_cmd, &line_proc)
    end

    def changesets(checkout_dir, from_identifier, to_identifier=Time.infinity, files=nil, &line_proc)
      checkout_dir = PathConverter.filepath_to_nativepath(checkout_dir, false)
      changesets = nil
      command = "svn #{changes_command(from_identifier, to_identifier, files)}"
      yield command if block_given?

      with_working_dir(checkout_dir) do
        IO.popen(command) do |stdout|
          parser = SVNLogParser.new(stdout, svnpath, checkout_dir)
          changesets = parser.parse_changesets(from_identifier, to_identifier, &line_proc)
        end
      end
      changesets
    end
    
    # url pointing to the root of the repo
    def repourl
      last = (svnpath.nil? || svnpath == "") ? -1 : -(svnpath.length)-2
      svnurl[0..last]
    end

  private

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
        raise "Didn't have permission to write to #{post_commit_file}. " +
              "Try to manually add the following line:\n\n#{trigger_command}\n\n" +
              "Finally make it executable with chmod g+x #{post_commit_file}\n\n"
      end
    end
    
    def install_win_trigger(trigger_command, damagecontrol_install_dir, &line_proc)
      post_commit_exists = File.exists?(post_commit_file)
      mode = post_commit_exists ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      File.open(post_commit_file, mode) do |file|
        file.puts("#{trigger_command}\n" )
      end
    end
    
    def svnrootdir
      last = (svnpath.nil? || svnpath == "") ? -1 : -(svnpath.length)-2
      result = svnurl["file://".length..last]
      # for windows, turn /c:/blabla into c:/blabla"
      if(result =~ /^\/[a-zA-Z]:/)
        result = result[1..-1]
      end
      result
    end

    def svnadmin(dir, cmd, &line_proc)
      svncommand("svnadmin", dir, cmd, &line_proc)
    end

    def svn(dir, cmd, &line_proc)
      svncommand("svn", dir, cmd, &line_proc)
    end

    def svncommand(executable, dir, cmd, &line_proc)
      command_line = "#{executable} #{cmd}"
      dir = File.expand_path(dir)
      with_working_dir(dir) do
        IO.popen(command_line) do |stdout|
          stdout.each_line do |line|
            yield line if block_given?
          end
        end
      end
    end
    
    def checked_out?(checkout_dir)
      rootentries = File.expand_path("#{checkout_dir}/.svn/entries")
      result = File.exists?(rootentries)
      result
    end

    def checkout_command(to_identifier, checkout_dir)
      checkout_dir = "\"#{checkout_dir}\""
      "checkout #{revision_option(nil, to_identifier)} #{svnurl} #{checkout_dir}"
    end

    def update_command(to_identifier)
      "update  #{revision_option(nil, to_identifier)}"
    end
    
    def changes_command(from_identifier, to_identifier, files)
      # http://svnbook.red-bean.com/svnbook-1.1/svn-book.html#svn-ch-3-sect-3.3
      # file_list = files.join('\n')
# WEIRD cygwin bug garbles this!?!?!?!
      "log --verbose #{revision_option(from_identifier, to_identifier)}"
    end

    def revision_option(from_identifier, to_identifier)
      from = nil
      if(from_identifier.is_a?(Time))
        from = svndate(from_identifier)
      else
        from = from_identifier
      end

      to = nil
      if(to_identifier.is_a?(Time))
        to = svndate(to_identifier)
      else
        to = to_identifier
      end

      revision_option = nil
      if(from && to.nil?)
        revision_option = "--revision #{from}:HEAD"
      elsif(from.nil? && to)
        revision_option = "--revision #{to}"
      elsif(from.nil? && to.nil?)
        revision_option = ""
      elsif(from && to)
        revision_option = "--revision #{from}:#{to}"
      end
      revision_option
    end
    
    def svndate(time)
      return nil unless time
      time.utc.strftime("\"{%Y-%m-%d %H:%M:%S +0000\"}")
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
      WINDOWS ? "#{svnrootdir}/hooks/post-commit.cmd" : "#{svnrootdir}/hooks/post-commit"
    end
    
  end
end
