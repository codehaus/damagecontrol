require 'drb'
require 'rubygems'
require 'needle'
require_gem 'rscm'
require 'damagecontrol/poller'
require 'damagecontrol/standard_persister'

# Wire up the whole DamageControl app with Needle's nice block based DI framework.
# I wonder - is BDI (Block Dependency Injection) a new flavour of DI?
REGISTRY = Needle::Registry.define do |b|
  b.persister do
    DamageControl::StandardPersister.new
  end 

  b.poller do 
    # Use a poller that persists the basic stuff
    DamageControl::Poller.new do |project, changesets|
      b.persister.save_changesets(project, changesets)
      b.persister.save_diffs(project, changesets)
      b.persister.save_rss(project)
      project.build(changesets.latest.identifier) do |build|
        # TODO: execute the real thing
        build.execute("hello!")
      end
    end
  end

  b.drb_server do 
    DamageControl::DrbServer.new('druby://localhost:9000')
  end
end
  
module DamageControl

  class App
    def run
      REGISTRY.poller.start
      REGISTRY.drb_server.start
  
      DRb.thread.join # Block forever
    end
  end

  # Drb top-level object that can be accessed by the web app.
  # The webapp should use this for any operations that are
  # lengthy.
  #
  class DrbServer
    def initialize(drb_url)
      @drb_url = drb_url
    end
    
    def start
      DRb.start_service(@drb_url, self)  
      Log.info "DamageControl server running on #{@drb_url}"
    end
  
    def save_project(project)
      project.save
    end

    def delete_project(project)
      project.delete
    end

    def checkout_project(project)
      project.checkout
    end
  end
  
end
