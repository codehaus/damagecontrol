require 'rubygems'
require 'needle'
require 'rscm'
require 'damagecontrol/poller'
require 'damagecontrol/standard_persister'

# Wire up the whole DamageControl app with Needle's nice block based DI framework.
# I wonder - is BDI (Block Dependency Injection) a new flavour of DI?
REGISTRY = Needle::Registry.define do |b|
  b.persister do
    DamageControl::StandardPersister.new
  end 

  b.poller do 
    DamageControl::Poller.new do |project, changesets|
      b.persister.save_changesets(project, changesets)
      b.persister.save_rss(project)
      changeset = changesets.latest
      project.execute_build(changeset.identifier, "Detected changes by polling #{project.scm.name}") do |build|
        env = {
          'PKG_BUILD' => changeset.identifier.to_s, # Rake standard
          'DAMAGECONTROL_BUILD_LABEL' => changeset.identifier.to_s, # For others
          'DAMAGECONTROL_CHANGED_FILES' => changeset.changes.collect{|change| change.path}.join(",")
        }
        build.execute(project.build_command, env)
        project.publish(build)
      end
      # This may take a while, so we do it after the build.
      b.persister.save_diffs(project, changesets)
    end
  end
end
  
module DamageControl

  class App
    def run
      REGISTRY.poller.start.join
    end
  end
  
end
