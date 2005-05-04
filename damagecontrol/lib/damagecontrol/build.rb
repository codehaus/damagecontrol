require 'rscm/path_converter'
require 'damagecontrol/project'

module DamageControl
  class BuildException < Exception
  end

  # Represents build-related data organised in the following file structure:
  #
  # File structure:
  #
  #   .damagecontrol/
  #     SomeProject/
  #       project.yaml
  #       checkout/
  #       revisions/
  #         2802/
  #           revision.yaml         (serialised Revision object)
  #           diffs/                 (serialised diff files)
  #           builds/                
  #             2005280271234500/    (timestamp of build start)
  #               stdout.log
  #               stderr.log
  #               artifacts/
  #
  class Build

    # TODO: we want to store the following additional info for a build (time related)
    #  * Total Duration
    #  * Duration of checkpoints (compile, test, javadocs...) - should be configurable in project.
    #  * 

    attr_reader :revision, :time, :stdout_file, :stderr_file
  
    # Loads an existing Build from disk
    def Build.load(revision, time)
      raise "Revision can't be nil" if revision.nil?
      raise "Revision's project can't be nil" if revision.project.nil?
      raise "Revision's dir can't be nil" if revision.dir.nil?

# TODO: use YAML! revision, time, reasons, exit_code, pid, command - stdout and stderr are methods, @dir excluded from YAML
      reasons_file = "#{revision.dir}/builds/#{time.ymdHMS}/reasons"
      reasons = File.exist?(reasons_file) ? File.open(reasons_file).read : "unknown build reason"
      Build.new(revision, time, reasons)
    end
  
    # Creates a new Build for a +revision+, created at +time+ and executed because of +reason+.
    def initialize(revision, time, reasons)
      @revision, @time, @reasons = revision, time, reasons

      raise "Revision can't be nil" if @revision.nil?
      raise "Revision's project can't be nil" if @revision.project.nil?
      raise "Revision's dir can't be nil" if @revision.dir.nil?

      @dir = File.expand_path("#{@revision.dir}/builds/#{identifier}")
      @stdout_file = "#{@dir}/stdout.log"
      @stderr_file = "#{@dir}/stderr.log"

      @exit_code_file = "#{@dir}/exit_code"
      @pid_file = "#{@dir}/pid"
      @command_file ="#{@dir}/command"
    end

    # Our unique id within the revision
    def identifier
      time.ymdHMS
    end

    # Executes +command+ with the environment variables +env+ and persists the command for future reference.
    # (This will prevent the same build from being executed in the future.)
    def execute(command, execute_dir, env)
      raise "Revision can't be nil" if @revision.nil?
      raise "Revision's project can't be nil" if revision.project.nil?
      raise "Revision's dir can't be nil" if revision.dir.nil?

      Log.debug "Executing build. Command file: #{@command_file}"
      raise BuildException.new("This build has already been executed and cannot be re-executed. It was executed with '#{File.open(@command_file).read}'") if File.exist?(@command_file)
      FileUtils.mkdir_p(@dir) unless File.exist?(@dir)
      File.open(@command_file, "w") do |io|
        io.write(command)
      end
      command_line = "#{command} > \"#{@stdout_file}\" 2> \"#{@stderr_file}\""

      begin
        with_working_dir(execute_dir) do
          env.each {|k,v| ENV[k]=v}
          Log.info "Executing '#{command_line}'"
          Log.info "Execution environment:"
          ENV.each {|k,v| Log.info("#{k}=#{v}")}
          IO.popen(command_line) do |io|
            File.open(@pid_file, "w") do |pid_io|
              pid_io.write("TODO: get the pid")
            end
            
            # there is nothing to read, since we're redirecting to file,
            # but we still need to read in order to block until the process is done.
            # TODO: don't redirect stdout - we want to intercept checkpoints/stages
            io.read
          end
        end
#      ensure
        exit_code = $? >> 8
        File.open(@exit_code_file, "w") do |io|
          io.write(exit_code)
        end
      end
    end

    # Returns the exit code of the build process, or nil if the process was killed
    def exit_code
      if(File.exist?(@exit_code_file))
        File.read(@exit_code_file).to_i
      else
        nil
      end
    end
    
    def successful?
      exit_code == 0
    end
    
    def status_message
      successful? ? "Successful" : "Failed"
    end

    # Returns the pid of the build process
    def pid
      File.read(@pid_file).to_i
    end
    
    def kill
      Process.kill("SIGHUP", pid)
    end
  end
end
