require File.dirname(__FILE__) + '/../test_helper'

class ScmFileTest < Test::Unit::TestCase

  def test_should_know_about_directory
    assert scm_files(:usr_bin).directory?
    assert !scm_files(:usr_bin_ruby).directory?
  end
  
  def test_should_find_file_by_path
    assert_equal scm_files(:usr_bin_ruby), ScmFile.find_by_path("usr/bin/ruby")
  end
  
  def test_should_find_or_create_by_directory_and_path_and_project
    foo = ScmFile.find_or_create_by_directory_and_path_and_project_id(true, "var/log/foo", projects(:project_1).id)
    assert_equal "var/log", foo.parent.path
    foo2 = ScmFile.find_or_create_by_directory_and_path_and_project_id(true, "var/log/bar", projects(:project_1).id)
    assert_equal foo.parent, foo2.parent
    foo3 = ScmFile.find_or_create_by_directory_and_path_and_project_id(true, "var/log/bar", projects(:project_2).id)
    assert_not_equal foo.parent, foo3.parent
  end
  
  def test_should_have_revision_info
    revisions = scm_files(:readme).revisions
    assert_equal 1, revisions.size
    assert_equal 789, revisions[0].identifier
    assert_equal "1.4.5", revisions[0].native_revision_identifier
  end
end
