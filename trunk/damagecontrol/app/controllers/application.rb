# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require 'damagecontrol/project'
require 'damagecontrol/build'
require 'damagecontrol/tracker'
require 'damagecontrol/scm_web'

class ApplicationController < ActionController::Base

  layout 'rscm'

  def initialize
    @sidebar_links = [
      {
        :controller => "project", 
        :action     => "new", 
        :image      => "/images/24x24/box_new.png",
        :name       => "New project"
      }
    ]
    @controller = self
  end

  # Loads the project specified by the +id+ parameter and places it into the @project variable  
  def load_project
    project_name = @params["id"]
    @project = DamageControl::Project.load(project_name)
  end

  def breadcrumbs
    subpaths = @request.path.split(/\//)
#    subpaths.collect { |p| link_to_unless_current(p) }.links.join(" ")
  end

protected

  # Override so we can get rid of the Content-Disposition
  # headers by specifying :no_disposition => true in options
  # This is needed when we want to send big files that are
  # *not* intended to pop up a save-as dialog in the browser.
  def send_file_headers!(options)
    options.update(DEFAULT_SEND_FILE_OPTIONS.merge(options))
    [:length, :type, :disposition].each do |arg|
      raise ArgumentError, ":#{arg} option required" if options[arg].nil?
    end

    headers = {
      'Content-Length'            => options[:length],
      'Content-Type'              => options[:type]
    }
    unless(options[:no_disposition])
      disposition = options[:disposition].dup || 'attachment'
      disposition <<= %(; filename="#{options[:filename]}") if options[:filename]
      headers.merge!(
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary'
      )
    end
        
    @headers.update(headers);
  end

  # Sets the links to display in the sidebar. Override this method in other controllers
  # To change what to display.
  def set_sidebar_links

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
  
  class Base
    def text_or_input(input, options)
      if(input)
        options[:class] = "setting-input" unless options[:class]
        tag("input", options)
      elsif(options[:value] =~ /^http?:\/\//)
        content_tag("a", options[:value], "href" => options[:value])
      else
        options[:value]
      end
    end
    
    def text_or_select(input, options)
      values = options.delete(:values)
      if(input)
        options[:class] = "setting-input" unless options[:class]
        
        option_tags = ""
        values.each do |value|
          option_attrs = {:value => value.class.name}
          option_attrs[:selected] = "true" if value.selected?
          option_tag = content_tag("option", value.name, option_attrs)
          option_tags << option_tag
        end
        content_tag("select", option_tags, options)
      else
        values.find {|v| v.selected?}.name
      end
    end
    
    # Creates an image with a tooltip that will show on mouseover.
    #
    # Options:
    # * <tt>:txt</tt> - The text to put in the tooltip. Can be HTML.
    # * <tt>:img</tt> - The image to display on the page. Defaults to '/images/16x16/about.png'
    def tip(options)
      tip = options.delete(:txt)
      options[:src] = options.delete(:img) || "/images/16x16/about.png"
      options[:onmouseover] = "Tooltip.show(event,#{tip})"
      options[:onmouseout] = "Tooltip.hide()"

      tag("img", options)
    end
  end
end

module DamageControl

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

class DamageControl::Build
  def small_image
    exit_code == 0 ? "/images/green-16.gif" : "/images/red-16.gif"
  end
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