# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'rscm'
require 'rscm/project'
require 'rscm/directories'

# Add some generic web capabilities to the RSCM classes

class ApplicationController < ActionController::Base
  include RSCM::Directories
end

module RSCM
  module Web
    module Configuration

      def selected?
        false
      end

      # Returns the partial form name
      def form
        $1.downcase if self.class.name =~ /.*::(.*)/
      end

    end
  end
end

class RSCM::AbstractSCM
  include RSCM::Web::Configuration
end

class RSCM::Tracker::Base
  include RSCM::Web::Configuration
end

class RSCM::Project
  include RSCM::Web::Configuration
end
