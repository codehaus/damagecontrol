require 'rubygems'
require 'drb'
require 'needle'
require_gem 'rscm'
require 'damagecontrol/poller'


REGISTRY = Needle::Registry.define do |b|
  b.poller     { DamageControl::Poller.new }
  b.drb_server { DamageControl::DrbServer.new('druby://localhost:9000') }
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
