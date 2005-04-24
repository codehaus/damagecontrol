require 'rubygems'
require 'yaml'
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
      
        b.queue do
          DamageControl::BuildQueue.new("#{basedir}/build_queue.yaml")
        end 

        b.poller do 
          DamageControl::Poller.new("#{basedir}/projects") do |project, changesets|
            b.persister.save_changesets(project, changesets)
            b.persister.save_rss(project)
            changeset = changesets.latest
      
            b.queue.enqueue(changeset, "Detected changesets by polling #{project.scm.name}")
          end
        end

        # We can't use builder - it conflicts with needle
        b.builder_ do
          DamageControl::Builder.new(b.queue)
        end 

      end
      
      threads = []

      threads << Thread.new do
        while(true)
          registry.builder_.build_next
          sleep 20
        end
      end
      threads << registry.poller.start
      
      # wait for each thread to die
      threads.each{ |t| t.join }
    end
  end
  
end
