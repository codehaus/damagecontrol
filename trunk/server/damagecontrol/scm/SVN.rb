require 'ftools'
require 'stringio'
require 'damagecontrol/scm/AbstractSCM'
require 'damagecontrol/scm/SVNLogParser'

module DamageControl

  class SVN < AbstractSCM

    def initialize(config_map)
      super(config_map)
      @svnurl = config_map["svnurl"] || required_config_param("svnurl")
      @svnprefix = config_map["svnprefix"] || required_config_param("svnprefix")
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
      # yeah, @svnurl is not a file path, but this works
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
    
    def cmd(dir, cmd, &proc)
      cmd_with_io(dir, cmd) do |io|
        io.each_line do |progress|
          if block_given? then yield progress else logger.debug(progress) end
        end
      end
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
          svn("add #{relative_filename}")
        end

        commit("adding #{relative_filename}")
      end
    end
  end
end
