require 'ftools'
require 'damagecontrol/scm/AbstractSCM'

module DamageControl

  class SVN < AbstractSCM

    def initialize(config_map)
      super(config_map)
      @svnurl = config_map["svnurl"] || required_config_param("svnurl")
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
      svn(working_dir, changes_command(from_time, to_time)) do |io|
        io.each_line do |line|
          puts line
        end
      end
    end

    def working_dir
      # yeah, @svnurl is not a file path, but this works
      subdir = File.basename(@svnurl)
      "#{checkout_dir}/#{subdir}"
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
      cmd(dir, "svn #{cmd}")
    end

    def svnadmin(dir, cmd, &proc)
      cmd(dir, "svnadmin #{cmd}")
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
    def initialize(basedir, subdir)
      @svnrootdir = "#{basedir}/svnroot"
      hack = "/" if windows?
      hack = "" unless hack
      @repo_url = "file://#{hack}#{@svnrootdir}"
      @project_url = "#{@repo_url}/#{subdir}"
      super("svnurl" => @project_url, "checkout_dir" => "#{basedir}/checkout")
      @subdir = subdir
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
