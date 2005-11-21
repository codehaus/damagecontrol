class SearchController < ApplicationController

  layout nil

  def query
    query = params[:q]
    @results = RevisionFile.find_by_contents(query)
  end
end
