require 'rscm'
require 'damagecontrol/tracker'

module DamageControl

  class Build
    def small_image
      exit_code == 0 ? "/images/green-16.gif" : "/images/red-16.gif"
    end
  end

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
  include DamageControl::Web::Configuration
end

class DamageControl::Tracker::Base
  include DamageControl::Web::Configuration
end

class DamageControl::Project
  include DamageControl::Web::Configuration
end

class RSCM::Change
  ICONS = {
    MODIFIED => "/images/16x16/document_edit.png",
    DELETED => "/images/16x16/document_delete.png",
    ADDED => "/images/16x16/document_add.png",
    MOVED => "/images/16x16/document_exchange.png",
  }
    
  def icon
    ICONS[@status] || "/images/16x16/document_warning.png"
  end
end