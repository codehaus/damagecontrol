require 'damagecontrol/visitor/diff_persister'
require 'damagecontrol/diff_parser'
require 'damagecontrol/diff_htmlizer'
require 'damagecontrol/visitor/diff_persister'
require 'damagecontrol/revision_ext'

class ScmController < ApplicationController

  # Creates the SCM repo
  def create
    load_project
    @project.scm.create_central
    redirect_to :controller => "project", :action => "view", :id => @project.name
  end

  def delete_working_copy
    load_project
    @project.delete_working_copy
    redirect_to :controller => "project", :action => "view", :id => @project.name
  end

  def diff_with_previous
    load_project
    revision_identifier = @params['revision_identifier'].to_identifier
    file_index = @params['file_index'].to_i
    standalone_page = @params['standalone_page']
    revision = @project.revision(revision_identifier)
    file = revision[file_index]
    html = ""
    diff_file = file.diff_file

    # persist the diff file if it doesn't exist
    retrieve_diff = !File.exist?(diff_file) || (File.exist?(diff_file) && File.open(diff_file).read == "")
    if(retrieve_diff)
      file.accept(DamageControl::Visitor::DiffPersister.new)
      if(!File.exist?(diff_file))
        render_text("Unable to retrieve diff")
        return
      end
    end

    html = ""
    dp = DamageControl::DiffParser.new
    File.open(diff_file) do |diffs_io|
      diffs = dp.parse_diffs(diffs_io)
      dh = DamageControl::DiffHtmlizer.new(html)
      diffs.accept(dh)
      if(html == "")
        html = "Diff was calculated, but was empty. (This may be a bug - new, moved, removed and binary files and are not supported yet)."
      end
    end
    render_text(html)
  end

end
