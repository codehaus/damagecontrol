module DamageControl
  module Process
    class Builder < Base

      def run
        forever do |project|
          execute_requested_builds_for(project)
        end
      end

      def execute_requested_builds_for(project)
        builds = project.pending_builds
        
        # Partition them in local and remote ones
        local_builds, slave_managed_builds = builds.partition {|build| build.build_executor.is_master}

        # The slave-managed builds are fast to build, since all that happens is to zip up the working copies.
        slave_managed_builds.each do |build|
          # TODO: we're not really executing. Find a better word maybe?
          build.execute!
        end

        # We'll only build one of the pending local builds to avoid spending too much time in one project.
        local_builds[0].execute! if local_builds[0]
      end
    end
  end
end