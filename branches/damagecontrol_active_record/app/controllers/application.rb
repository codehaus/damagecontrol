# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
end

class Build < ActiveRecord::Base
  def small_image
    "foo"
  end
end