require 'rscm'
require 'damagecontrol/build'

module RSCM
  class ChangeSet
    attr_accessor :project

    def to_yaml_properties
      props = instance_variables
      props.delete("@project")
      props.sort!
    end
    
    def dir
      "#{@project.dir}/changesets/#{identifier}"
    end

    # Creates, persists and executes a Build for this changeset. 
    # Should be called with a block of arity 1 that will receive the build *after*
    # the build has terminated execution. (Typically given to build publishers).
    def build!(project, build_reason)
      @project = project

      # First, tell project to checkout to "ourself"
      @project.checkout(identifier)

      build = DamageControl::Build.new(self, Time.now.utc, build_reason)
      env = {
        'PKG_BUILD' => identifier.to_s, # Rake standard
        'DAMAGECONTROL_BUILD_LABEL' => identifier.to_s, # For others
        'DAMAGECONTROL_CHANGED_FILES' => changes.collect{|change| change.path}.join(",")
      }
      # TODO: persist here, nott in app.rb
      build.execute(project.build_command, env)
      yield build
    end

    # Returns an array of existing Build s.
    def builds
      builds_glob = "#{dir}/builds/*"
      Log.debug "Builds Glob: #{builds_glob}"
      Dir[builds_glob].collect do |dir|
        # The dir's basename will always be a Time
        time = Time.parse_ymdHMS(File.basename(dir))
        DamageControl::Build.load(self, time)
      end
    end

    # Returns the latest build.
    def latest_build
      builds[-1]
    end

  end

  class Change
    attr_accessor :changeset

    def to_yaml_properties
      props = instance_variables
      props.delete("@changeset")
      props.sort!
    end
    
    def diff_file
      "#{@changeset.dir}/diffs/#{path}.diff"
    end
  end
end