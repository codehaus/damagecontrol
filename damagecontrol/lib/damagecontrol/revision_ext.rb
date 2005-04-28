require 'rscm'
require 'damagecontrol/build'

module RSCM
  class Revision
    attr_accessor :project

    def to_yaml_properties
      props = instance_variables
      props.delete("@project")
      props.sort!
    end
    
    def dir
      "#{@project.dir}/revisions/#{identifier}"
    end

    # Creates, persists and executes a Build for this revision. 
    # Usually, this method should only be called by a Builder.
    def build!(build_reason)

      build = DamageControl::Build.new(self, Time.now.utc, build_reason)

      begin
        @project.scm.checkout(identifier)

        env = {
          'PKG_BUILD' => identifier.to_s, # Rake standard
          'DAMAGECONTROL_BUILD_LABEL' => identifier.to_s, # For others
          'DAMAGECONTROL_CHANGED_FILES' => self.collect{|change| change.path}.join(",")
        }
      
        # TODO: persist here, not in app.rb
        build.execute(@project.build_command, @project.execute_dir, env)
      rescue => e
        File.open(build.stderr_file, "w") do |io|
          e.write("DamageControl failed. This may or may not be a bug!\n\n")
          e.write(e.backtrace.join("\n"))
        end
      end
      @project.publish(build)
    end

    # Returns an array of existing (archived) Build s.
    def builds
      builds_glob = "#{dir}/builds/*"
      Log.debug "Builds Glob: #{builds_glob}"
      Dir[builds_glob].collect do |dir|
        # The dir's basename will always be a Time
        time = Time.parse_ymdHMS(File.basename(dir))
        build(time)
      end
    end
    
    # Returns a specific existing (archived) Build for +time+
    def build(time)
      DamageControl::Build.load(self, time)
    end

    # Returns the latest Build.
    def latest_build
      builds[-1]
    end
    
    alias old_eq ==
    def ==(other)
      old_eq(other) && self.project == other.project
    end

  end

  class RevisionFile
    attr_accessor :revision

    def to_yaml_properties
      props = instance_variables.dup
      props.delete("@revision")
      props.sort!
    end
    
    def diff_file
      "#{@revision.dir}/diffs/#{path}.diff"
    end
  end
end