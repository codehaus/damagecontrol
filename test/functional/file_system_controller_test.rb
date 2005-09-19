require File.dirname(__FILE__) + '/../test_helper'
require 'file_system_controller'

# Re-raise errors caught by the controller.
class FileSystemController; def rescue_action(e) raise e end; end

class FileSystemControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = FileSystemController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    FileUtils.rm_rf(Artifact::ARTIFACT_DIR) if File.exist?(Artifact::ARTIFACT_DIR)
  end

  def test_should_drill_down_in_directories
    FileUtils.mkdir_p(Artifact::ARTIFACT_DIR + "/gems")
    FileUtils.mkdir_p(Artifact::ARTIFACT_DIR + "/java/picocontainer/jars")
    FileUtils.mkdir_p(Artifact::ARTIFACT_DIR + "/java/nanocontainer/jars")
    File.open(Artifact::ARTIFACT_DIR + "/java/nanocontainer/jars/Hey.java", "w") do |io|
      io.puts "public class Hey {}"
    end
    
    get :browse, :path => nil
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/gems"}
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java"}

    get :browse, :path => ["java"]
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/picocontainer"}
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/nanocontainer"}

    get :browse, :path => ["java", "nanocontainer", "jars"]
    assert_tag :tag => "a", :attributes => {:href => "/artifacts/java/nanocontainer/jars/Hey.java"}
    
    get :browse, :path => ["java", "nanocontainer", "jars", "Hey.java"]
    #assert_equal "public class Hey {}", @response.body
  end

  def test_should_map_paths
    assert_routing("artifacts", 
      {:controller => "file_system", :action => "browse", :path => []})

    assert_routing("artifacts/check/your/head", 
      {:controller => "file_system", :action => "browse", :path => ["check", "your", "head"]})
  end
end
