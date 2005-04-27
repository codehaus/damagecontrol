require 'rubygems'
require 'yaml'
require 'needle'
require 'rscm'
require 'damagecontrol/revision_ext'
require 'damagecontrol/poller'
require 'damagecontrol/builder'
require 'damagecontrol/build_queue'
require 'damagecontrol/build_request_poller'
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

  # The main entry point for the DC daemon
  class App
    def run
      # Delete the old build queue
      FileUtils.rm_rf("#{basedir}/build_queue.yaml") if File.exist?("#{basedir}/build_queue.yaml")
    
      # Wire up the whole DamageControl app with Needle's nice block based DI framework.
      # I wonder - is BDI (Block Dependency Injection) a new flavour of DI?
      registry = Needle::Registry.define do |b|
        b.persister do
          DamageControl::StandardPersister.new
        end 

        b.build_queue do
          DamageControl::BuildQueue.new("#{basedir}/build_queue.yaml")
        end 

        b.build_request_poller do
          DamageControl::BuildRequestPoller.new(basedir, b.build_queue)
        end 

        b.scm_poller do 
          DamageControl::Poller.new("#{basedir}/projects") do |project, revisions|
            b.persister.save_revisions(project, revisions)
            b.persister.save_rss(project)
            revisions.each do |revision|
              b.build_queue.enqueue(revision, "Detected revisions by polling #{project.scm.name}")
            end
          end
        end

        # We can't use builder - it conflicts with needle
        b.builder_ do
          DamageControl::Builder.new(b.build_queue)
        end 

      end
      
      threads = []
      threads << Thread.new do
        while(true)
          registry.builder_.build_next
        end
      end

      # a poller that picks up request on file every 5 secs
      threads << Thread.new do
        while(true)
          registry.build_request_poller.poll
          sleep 5
        end
      end

      threads << registry.scm_poller.start

      # wait for each thread to die
      threads.each{ |t| t.join }
    end
  end
  
end
