require 'rubygems'
require 'needle'
require 'rscm'
require 'damagecontrol/changeset_ext'
require 'damagecontrol/poller'
require 'damagecontrol/standard_persister'
require 'damagecontrol/publisher/base'

def basedir
  if(ENV['DAMAGECONTROL_HOME'])
    ENV['DAMAGECONTROL_HOME']
  elsif(WINDOWS)
    RSCM::PathConverter.nativepath_to_filepath("#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}/.damagecontrol").gsub(/\\/, "/")
  else
    "#{ENV['HOME']}/.damagecontrol"
  end
end
  
module DamageControl

  class App
    def run
      # Wire up the whole DamageControl app with Needle's nice block based DI framework.
      # I wonder - is BDI (Block Dependency Injection) a new flavour of DI?
      registry = Needle::Registry.define do |b|
        b.persister do
          DamageControl::StandardPersister.new
        end 
      
        b.poller do 
          DamageControl::Poller.new("#{basedir}/projects") do |project, changesets|
            b.persister.save_changesets(project, changesets)
            b.persister.save_rss(project)
            changeset = changesets.latest
      
            changeset.build!(project, "Detected changes by polling #{project.scm.name}") do |build|
              project.publish(build)
            end
            # TODO: do this in a publisher that can be turned off if an other SCMWeb is used.
            # Disable by default if other SCMWeb is specified.
            # This may take a while, so we do it after the build.
            b.persister.save_diffs(changesets)
          end
        end
      end
      registry.poller.start.join
    end
  end
  
end
