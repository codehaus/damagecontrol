# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'rscm'

# Start Drb - this is how we communicate with the daemon.
DRb.start_service()
Rscm = DRbObject.new(nil, 'druby://localhost:9000')

class ApplicationController < ActionController::Base

  def initialize
    @controller = self
    @tasks = ["FOO", "BAR"]
  end
  
  def breadcrumbs
    subpaths = @request.path.split(/\//)
#    subpaths.collect { |p| link_to_unless_current(p) }.links.join(" ")
  end
  
end

module ActionView
  module Helpers
    module UrlHelper
      # Modify the original behaviour of +link_to+ so that the link
      # includes the client's timezone as URL param +timezone+ in the request.
      # Can be used by server to adjust formatting of UTC dates so they match the client's time zone.
      def convert_confirm_option_to_javascript!(html_options)
        # We're adding this JS call to add the timezone info as a URL param.
        html_options["onclick"] = "intercept(this);"
        if html_options.include?(:confirm)
          html_options["onclick"] += "return confirm('#{html_options[:confirm]}');"
          html_options.delete(:confirm)
        end
      end
    end
  end
end

module RSCM

  # Add some generic web capabilities to the RSCM classes
  module Web
    module Configuration

      def selected?
        false
      end

      # Returns the short lowercase name. Used for javascript and render_partial.
      def short
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
