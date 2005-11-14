#require_dependency 'sparklines'
require_dependency 'damagecontrol'

Struct.new("Feed", :type, :url_options, :title) unless defined? Struct::Feed

class ApplicationController < ActionController::Base
  include RestResource

  COMMIT_MSG_TIPS = [
    "bug_ids_commit_msg",
    "textile_commit_msg"
    # TODO: only display this if the tracker supports it via tracker.can_close?/can_comment?
    # "bug_edit_commit_msg"
  ]
  PROJECT_SETTING_TIPS = [
#    "triggering",
    "importing",
    "build_env_vars"
  ]
  TIPS = {
    :project_settings => PROJECT_SETTING_TIPS,
    :commit_msg => COMMIT_MSG_TIPS,
    :any => COMMIT_MSG_TIPS + PROJECT_SETTING_TIPS
  }

  prepend_before_filter :load_projects, :random_tip, :feeds
  append_before_filter :page_title
  
  def notice(msg)
    flash[:notice] = msg
  end
  
protected
  
  def feeds
    @feeds ||= []
  end
  
  def random_tip
    # TODO: perhaps keep a counter in the session and show sequentially?
    tips = TIPS[tip_category]
    tip(tips[rand(tips.length)])
  end
  
  # subclasses can override this method to specify a more specific tip category
  def tip_category
    :any
  end
  
  # call this method from an action to display a specific tip
  def tip(template_name)
    @template_for_tip = "tips/#{template_name}"
  end
  
  def page_title
    @page_title = "DamageControl"
  end

private

  # Loads all projects so that the right column can be populated properly
  def load_projects
    @projects = Project.find(:all, :order => "name")
  end
end
