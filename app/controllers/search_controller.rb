class SearchController < ApplicationController

  layout nil

  def query
    @search = params[:q]
    @results = []
    if(@search != "")
      index = FerretConfig::get_index(:create_if_missing => false)
      index.search_each("file_content:\"#{@search}\"") do |doc, score|
        @results << index[doc]
      end
    end
    @headers["Content-Type"] = "text/html; charset=utf-8"
  end
end
