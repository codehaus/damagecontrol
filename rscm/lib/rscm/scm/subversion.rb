require 'rscm/base'
require 'rscm/path_converter'
require 'rscm/line_editor'
require 'rscm/scm/subversion_log_parser'

module RSCM

  # RSCM implementation for Subversion.
  #
  # You need the svn/svnadmin executable on the PATH in order for it to work.
  #
  # NOTE: On Cygwin these have to be the win32 builds of svn/svnadmin and not the Cygwin ones.
  class Subversion < Base
    
    include FileUtils
    include PathConverter
    
    attr_accessor :url
    attr_accessor :path
    attr_accessor :username
    attr_accessor :password

    def initialize(url="", path="")
      @url, @path = url, path
      @username = ""
      @password = ""
    end

    def to_identifier(raw_identifier)
      raw_identifier.to_i
    end
    
    def add(relative_filename, options={})
      svn("add #{relative_filename}", options)
    end

    def move(relative_src, relative_dest, options={})
      svn("mv #{relative_src} #{relative_dest}", options)
    end

    def transactional?
      true
    end

    def uptodate?(identifier, options={})
      if(!checked_out?)
        false
      else
        rev = identifier.nil? ? head_revision_identifier(options) : identifier 
        local_revision_identifier(options) == rev
      end
    end

    def commit(message, options={})
      svn(commit_command(message), options)
      # We have to do an update to get the local revision right
      svn("update", options)
    end

    def label
      local_revision_identifier.to_s
    end

    def diff(file, options={}, &block)
      cmd = "svn diff --revision #{file.previous_native_revision_identifier}:#{file.native_revision_identifier} \"#{url}/#{file.path}\""
      execute(cmd, options) do |io|
        return(yield(io))
      end
    end
    
    def open(revision_file, options, &block)
      cmd = "svn cat #{url}/#{revision_file.path}@#{revision_file.native_revision_identifier}"
      execute(cmd, options) do |io|
        return(yield(io))
      end
    end

    def can_create_central?
      local?
    end

    def destroy_central
      if(File.exist?(svnrootdir) && local?)
        FileUtils.rm_rf(svnrootdir)
      else
        raise "Cannot destroy central repository. '#{svnrootdir}' doesn't exist or central repo isn't local to this machine"
      end
    end

    def central_exists?
      if(local?)
        File.exists?("#{svnrootdir}/db")
      else
        # Do a simple command over the network
        # If the repo/path doesn't exist, we'll get zero output
        # on stdout (and an error msg on std err).
        exists = false
        cmd = "svn log #{url} -r HEAD"
        execute(cmd) do |stdout|
          stdout.each_line do |line|
            exists = true
          end
        end
        exists
      end
    end

    def supports_trigger?
      true
      # we'll assume it supports trigger even if not local. this is to ensure user interfaces
      # can display appropriate options, even if the object is not 'fully initialised'
      # local?
    end

    def trigger_mechanism
      "hooks/post-commit"
    end
    
    def create_central(options={})
      options = options.dup.merge({:dir => svnrootdir})
      native_path = PathConverter.filepath_to_nativepath(svnrootdir, true)
      mkdir_p(PathConverter.nativepath_to_filepath(native_path))
      svnadmin("create #{native_path}", options)
      if(@path && @path != "")
        options = options.dup.merge({:dir => "."})
        # create the directories
        paths = @path.split("/")
        paths.each_with_index do |p,i|
          p = paths[0..i]
          u = "#{repourl}/#{p.join('/')}"
          svn("mkdir #{u} -m \"Adding directories\"", options)
        end
      end
    end

    def install_trigger(trigger_command, trigger_files_checkout_dir, options={})
      if (WINDOWS)
        install_win_trigger(trigger_command, trigger_files_checkout_dir, options)
      else
        install_unix_trigger(trigger_command, trigger_files_checkout_dir, options)
      end
    end
    
    def uninstall_trigger(trigger_command, trigger_files_checkout_dir, options={})
      File.comment_out(post_commit_file, /#{Regexp.escape(trigger_command)}/, nil)
    end
    
    def trigger_installed?(trigger_command, trigger_files_checkout_dir, options={})
      return false unless File.exist?(post_commit_file)
      not_already_commented = LineEditor.comment_out(File.new(post_commit_file), /#{Regexp.escape(trigger_command)}/, "# ", "")
      not_already_commented
    end
    
    def import_central(options)
      import_cmd = "import #{url} -m \"#{options[:message]}\""
      svn(import_cmd, options)
    end

    def revisions(from_identifier, options={})
      options = {
        :from_identifier => from_identifier,
        :to_identifier => Time.infinity, 
        :relative_path => "",
        :dir => Dir.pwd
      }.merge(options)
      
      checkout_dir = PathConverter.filepath_to_nativepath(@checkout_dir, false)
      revisions = nil
      command = "svn #{changes_command(options[:from_identifier], options[:to_identifier], options[:relative_path])}"
      execute(command, options) do |stdout|
        parser = SubversionLogParser.new(stdout, @url)
        revisions = parser.parse_revisions
      end
      revisions
    end
    
    # url pointing to the root of the repo
    def repourl
      last = (path.nil? || path == "") ? -1 : -(path.length)-2
      url[0..last]
    end

    def checked_out?
      rootentries = File.expand_path("#{checkout_dir}/.svn/entries")
      result = File.exists?(rootentries)
      result
    end

  protected

    def checkout_silent(to_identifier, options)
      checkout_dir = PathConverter.filepath_to_nativepath(@checkout_dir, false)
      mkdir_p(@checkout_dir)
      if(checked_out?)
        svn(update_command(to_identifier), options)
      else
        svn(checkout_command(to_identifier), options)
      end
    end

    def ignore_paths
      [/\.svn\/.*/]
    end

  private

    def local_revision_identifier(options)
      local_revision_identifier = nil
      svn("info", options) do |line|
        if(line =~ /Revision: ([0-9]*)/)
          return $1.to_i
        end
      end
    end

    def head_revision_identifier(options)
      # This command only seems to yield any changesets if the url is the root of
      # the repo, which we don't know in the case where path is not specified (likely)
      # We therefore don't specify it and get the latest revision from the full url instead.
      # cmd = "svn log #{login_options} #{repourl} -r HEAD"
      cmd = "svn log #{login_options} #{url}"
      execute(cmd, options) do |stdout|
        parser = SubversionLogParser.new(stdout, @url)
        revisions = parser.parse_revisions
        revisions[0].identifier
      end
    end

    def install_unix_trigger(trigger_command, damagecontrol_install_dir, options)
      post_commit_exists = File.exists?(post_commit_file)
      mode = post_commit_exists ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      begin
        File.open(post_commit_file, mode) do |file|
          file.puts("#!/bin/sh") unless post_commit_exists 
          file.puts("#{trigger_command}\n" )
        end
        File.chmod(0744, post_commit_file)
      rescue
        raise ["Didn't have permission to write to #{post_commit_file}.",
              "Try to manually add the following line:",
              trigger_command,
              "Finally make it executable with chmod g+x #{post_commit_file}"]
      end
    end
    
    def install_win_trigger(trigger_command, damagecontrol_install_dir, options)
      post_commit_exists = File.exists?(post_commit_file)
      mode = post_commit_exists ? File::APPEND|File::WRONLY : File::CREAT|File::WRONLY
      begin
        File.open(post_commit_file, mode) do |file|
          file.puts("#{trigger_command}\n" )
        end
      rescue
        raise ["Didn't have permission to write to #{post_commit_file}.",
              "Try to manually add the following line:",
              trigger_command]
      end
    end
    
    def svnrootdir
      last = (path.nil? || path == "") ? -1 : -(path.length)-2
      result = url["file://".length..last]
      # for windows, turn /c:/blabla into c:/blabla"
      if(result =~ /^\/[a-zA-Z]:/)
        result = result[1..-1]
      end
      result
    end

    def svnadmin(cmd, options={}, &proc)
      svncommand("svnadmin", cmd, options, &proc)
    end

    def svn(cmd, options={}, &proc)
      svncommand("svn", cmd, options, &proc)
    end

    def svncommand(executable, cmd, options, &proc)
      command_line = "#{executable} #{cmd}"
      execute(command_line, options) do |stdout|
        stdout.each_line do |line|
          yield line if block_given?
        end
      end
    end
    
    def checkout_command(to_identifier)
      cd = "\"#{checkout_dir}\""
      raise "checkout_dir not set" if cd == ""
      "checkout #{login_options} #{url} #{cd} #{revision_option(nil,to_identifier)}"
    end

    def update_command(to_identifier)
      "update #{login_options} #{revision_option(nil,to_identifier)}"
    end
    
    def changes_command(from_identifier, to_identifier, relative_path)
      # http://svnbook.red-bean.com/svnbook-1.1/svn-book.html#svn-ch-3-sect-3.3
      # file_list = files.join('\n')
      full_url = relative_path ? "#{url}/#{relative_path}" : ""
      cmd = "log --verbose #{login_options} #{revision_option(from_identifier, to_identifier)} #{full_url}"
      cmd
    end

    def login_options
      result = ""
      u = @username ? @username.strip : ""
      p = @password ? @password.strip : "
      result << "--username #{u} " unless u == ""
      result << "--password #{p} " unless p == ""
      result
    end

    def revision_option(from_identifier, to_identifier)
      # The inclusive start
      from = nil
      if(from_identifier.is_a?(Time))
        from = svndate(from_identifier + 1)
      elsif(from_identifier.is_a?(Numeric))
        from = from_identifier + 1
      elsif(!from_identifier.nil?)
        raise "from_identifier must be Numeric, Time or nil. Was: #{from_identifier} (#{from_identifier.class.name})"
      end

      to = nil
      if(to_identifier.is_a?(Time))
        to = svndate(to_identifier)
      elsif(to_identifier.is_a?(Numeric))
        to = to_identifier
      elsif(!from_identifier.nil?)
        raise "to_identifier must be Numeric, Time or nil. Was: #{to_identifier} (#{to_identifier.class.name})"
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
      time.utc.strftime("{\"%Y-%m-%d %H:%M:%S\"}")
    end

    def commit_command(message)
      "commit -m \"#{message}\""
    end
    
    def local?
      if(url =~ /^file:/)
        return true
      else
        return false
      end
    end

    def post_commit_file
      # We actualy need to use the .cmd when on cygwin. The cygwin svn post-commit
      # hook is hosed. We'll be relying on native windows
      if(local?)
        WINDOWS ? "#{svnrootdir}/hooks/post-commit.cmd" : "#{svnrootdir}/hooks/post-commit"
      else
        raise "The repository is not local. Cannot install or uninstall trigger."
      end
    end
    
  end
end
