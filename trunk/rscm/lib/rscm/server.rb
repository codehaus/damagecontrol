require 'drb'
require 'rscm'
require 'needle'

module RSCM
  # The Server is an object that is bound as a Drb top-level
  # object, and can be accessed by the web app. It should run
  # within a separate Ruby interpreter from the one running
  # the web app.
  class Server
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

REGISTRY = Needle::Registry.define do |b|
  b.poller { RSCM::Poller.new }
end

REGISTRY.poller.start

url = 'druby://localhost:9000'
DRb.start_service(url, RSCM::Server.new)  
puts "RSCM server running on #{url}"
DRb.thread.join # Don't exit just yet!
