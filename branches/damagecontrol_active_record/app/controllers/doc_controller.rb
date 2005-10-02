class DocController < ApplicationController
  append_before_filter :sidebar
  
private

  def sidebar
    @template_for_left_column = "doc/sidebar"
  end
end
