require File.dirname(__FILE__) + '/../test_helper'
require 'file_system_controller'

# Re-raise errors caught by the controller.
class FileSystemController; def rescue_action(e) raise e end; end

class FileSystemControllerTest < Test::Unit::TestCase
  fixtures :directories, :artifacts
  
  def setup
    @controller = FileSystemController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_drill_down_in_directories
    gems = Directory.lookup(["gems"], true)
    java = Directory.lookup(["java", "picocontainer", "jars"], true)
    java = Directory.lookup(["java", "picocontainer", "poms"], true)
    java = Directory.lookup(["java", "nanocontainer", "jars"], true)
    
    get :dir, :path => []
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/gems"}
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java"}

    get :dir, :path => ["java"]
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/picocontainer"}
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/nanocontainer"}

    get :dir, :path => ["java", "picocontainer"]
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/picocontainer/jars"}
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/picocontainer/poms"}
  end

  def test_should_map_paths
    assert_routing("artifacts", 
      {:action => "dir", :controller => "file_system", :path => []})

    assert_routing("artifacts/check/your/head", 
      {:action => "dir", :controller => "file_system", :path => ["check", "your", "head"]})

    assert_routing("artifacts", 
      {:action => "dir", :controller => "file_system", :path => []})
  end
end
