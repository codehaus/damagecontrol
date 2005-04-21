require 'rubygems'
require 'needle'
require 'rscm'
require 'damagecontrol/changeset_ext'
require 'damagecontrol/poller'
require 'damagecontrol/builder'
require 'damagecontrol/build_queue'
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
      
        b.builder do
          # TODO: use some sort of composite builder here.
          # It must be multithreaded and preferrably configurable via web
          DamageControl::Builder.new
        end 

        b.queue do
          DamageControl::BuildQueue.new
        end 

        b.poller do 
          DamageControl::Poller.new("#{basedir}/projects") do |project, changesets|
            b.persister.save_changesets(project, changesets)
            b.persister.save_rss(project)
            changeset = changesets.latest
      
            b.queue.enqueue(changeset, "Detected changesets by polling #{project.scm.name}")

            # TODO: do this on-demand with AJAX
#            b.persister.save_diffs(changesets)
          end
        end
      end
      
      threads = []

      threads << registry.poller.start
      
      # wait for each thread to die
      threads.each{ |t| t.join }
    end
  end
  
end
