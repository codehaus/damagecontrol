require 'damagecontrol/visitor/diff_persister'
require 'damagecontrol/diff_parser'
require 'damagecontrol/diff_htmlizer'
require 'damagecontrol/visitor/diff_persister'
require 'damagecontrol/changeset_ext'

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

  def change
    load_project
    changeset_identifier = @params['changeset_identifier'].to_identifier
    change_index = @params['change_index'].to_i
    changeset = @project.changeset(changeset_identifier)
    change = changeset[change_index]
    change.accept(DamageControl::Visitor::DiffPersister.new)

    html = ""
    dp = DamageControl::DiffParser.new
    diff_file = change.diff_file
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
    render_text(html)

  end

end
