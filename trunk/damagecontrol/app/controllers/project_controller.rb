require 'rscm'
require 'damagecontrol/directories'
require 'damagecontrol/diff_parser'
require 'damagecontrol/diff_htmlizer'

class ProjectController < ApplicationController
  SCMS = [
# Uncomment this to see Mooky in action in the web interface!
#    RSCM::Mooky,
    RSCM::CVS, 
    RSCM::SVN, 
    RSCM::StarTeam
  ]

  TRACKERS = [
    DamageControl::Tracker::Null, 
    DamageControl::Tracker::Bugzilla, 
    DamageControl::Tracker::JIRA,
    DamageControl::Tracker::RubyForge,
    DamageControl::Tracker::SourceForge,
    DamageControl::Tracker::Scarab,
    DamageControl::Tracker::Trac
  ]

  SCM_WEBS = [
#    SCMWeb::Null.new, 
#    SCMWeb::ViewCVS.new, 
#    SCMWeb::Fisheye.new
  ]

  def initialize
    super
    @navigation_name = "changesets_list"
  end

  def index
    @projects = DamageControl::Project.find_all
    @navigation_name = "null"
  end

  def new
    @project = DamageControl::Project.new
    @scms = SCMS.collect {|o| o.new}
    first_scm = @scms[0]
    def first_scm.selected?
      true
    end
    @trackers = TRACKERS.collect {|o| o.new}
    first_tracker = @trackers[0]
    def first_tracker.selected?
      true
    end
    @edit = true
    @new_project = true
    render_action("view")
  end

  def view
    return render_text("No project specified") unless @params["id"]
    @edit = false
    load
  end

  def edit
    @edit = true
    load
    render_action("view")
  end
  
  def changesets_rss
    project = RSCM::Project.load(@params["id"])
    send_file(project.changesets_rss_file)
  end

  def delete
    load_project
    begin
      Rscm.delete_project(project)
    rescue => e
      return render_text("Couldn't connect to RSCM server. Please make sure it's running.<br>" + e.message)
    end
    index
  end

  def save
    project         = instantiate_from_params("project")
    project.scm     = instantiate_from_params("scm")
    project.tracker = instantiate_from_params("tracker")
    
    begin
      Rscm.save_project(project)
    rescue => e
      $stderr.puts(e.backtrace.join("\n"))
      return render_text("Couldn't connect to RSCM server. Please make sure it's running.<br>" + e.message)
    end

    redirect_to(:action => "view", :id => project.name)
  end
  
  def changesets
    load
    last_changeset_id = @params["changeset"]
    @changesets = @project.changesets(last_changeset_id.to_id, 1)    
    @changesets.accept(HtmlDiffVisitor.new(@project))
  end

protected

  # Visitor that adds a method called +html_diff+ to each change
  class HtmlDiffVisitor
    def initialize(project)
      @project = project
    end
    
    def visit_changesets(changesets)
    end

    def visit_changeset(changeset)
      @changeset = changeset
    end

    def visit_change(change)
      def change.html_diff=(html)
        @html = html
      end

      def change.html_diff
        @html
      end

      html = ""
      dp = DamageControl::DiffParser.new
      diff_file = DamageControl::Directories.diff_file(@project.name, @changeset, change)
      if(File.exist?(diff_file))
        File.open(diff_file) do |diffs_io|
          diffs = dp.parse_diffs(diffs_io)
          dh = DamageControl::DiffHtmlizer.new(html)
          diffs.accept(dh)
          if(html == "")
            html = "Diff was calculated, but was empty. (This may be a bug - new, moved and binary files and are not supported yet)."
          end
        end
      else
        html = "Diff not calculated yet."
      end
      change.html_diff = html
    end
  end

  def set_sidebar_links
    if(@project.exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "edit",
        :id         => @project.name,
        :image      => "/images/24x24/wrench.png",
        :name       => "Edit #{@project.name} settings"
      }
    end

#    if(@project.exists?)
#      @sidebar_links << {
#        :controller => "project", 
#        :action     => "delete", 
#        :id         => @project.name,
#        :image      => "/images/24x24/box_delete.png",
#        :name       => "Delete #{@project.name} project"
#      }
#    end

    if(@project.exists? && @project.scm && !@project.scm.exists? && @project.scm.can_create?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "create", 
        :id         => @project.name,
        :image      => "/images/24x24/safe_new.png",
        :name       => "Create #{@project.scm.name} repository"
      }
    end

#    if(@project.exists? && !@project.checked_out?)
#      @sidebar_links << {
#        :controller => "scm", 
#        :action     => "checkout", 
#        :id         => @project.name,
#        :image      => "/images/24x24/safe_out.png",
#        :name       => "Check out from #{@project.scm.name}"
#      }
#    end

    if(@project.exists? && @project.checked_out?)
      @sidebar_links << {
        :controller => "files", 
        :action     => "list",
        :id         => @project.name,
        :image      => "/images/24x24/folders.png",
        :name       => "Browse working copy"
      }
    end

    if(@project.exists? && @project.checked_out?)
      @sidebar_links << {
        :controller => "scm", 
        :action     => "delete_working_copy", 
        :id         => @project.name,
        :image      => "/images/24x24/garbage.png",
        :name       => "Delete working copy"
      }
    end

    if(@project.exists?)
      @sidebar_links << {
        :href       => @project.tracker.url, 
        :image      => "/images/24x24/scroll_information.png",
        :name       => @project.tracker.name
      }
    end

    if(@project.exists? && @project.home_page && @project.home_page != "")
      @sidebar_links << {
        :href       => @project.home_page, 
        :image      => "/images/24x24/home.png",
        :name       => "#{@project.name} home page"
      }
    end

    if(@project.changesets_rss_exists?)
      @sidebar_links << {
        :controller => "project", 
        :action     => "changesets_rss", 
        :id         => @project.name,
        :image      => "/images/rss.gif",
        :name       => "Changesets RSS"
      }
    end

  end

private

  def load
    load_project

    scm = @project.scm
    def scm.selected?
      true
    end

    tracker = @project.tracker
    def tracker.selected?
      true
    end

    # Make a dupe of the scm/tracker lists and substitute with project's value
    @scms = SCMS.collect {|o| o.new}
    @scms.each_index {|i| @scms[i] = @project.scm if @scms[i].class == @project.scm.class}

    @trackers = TRACKERS.collect {|o| o.new}
    @trackers.each_index {|i| @trackers[i] = @project.tracker if @trackers[i].class == @project.tracker.class}

    @linkable_changesets = @project.changesets(@project.latest_changeset_id, 10)
    @select_changeset_ids = @project.changeset_ids[0..-(@linkable_changesets.length+1)]

    set_sidebar_links
  end

  # Instantiates an object from parameters
  def instantiate_from_params(param)
    class_name = @params[param]
    clazz = eval(class_name)
    ob = clazz.new
    attribs = @params[class_name] || {}
    attribs.each do |k,v|
      ob.send("#{k}=", v)
    end
    ob
  end

end
