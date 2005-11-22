class SearchController < ApplicationController

  layout nil

  def query
    @query = params[:q].strip
    revision_files = @query != "" ? RevisionFile.find_by_path_or_contents(@query) : []
    render :partial => "revision_file/overview", :collection => revision_files
  end
end
