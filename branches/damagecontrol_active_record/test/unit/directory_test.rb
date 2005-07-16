require File.dirname(__FILE__) + '/../test_helper'

class DirectoryTest < Test::Unit::TestCase
  fixtures :directories, :artifacts

  def test_should_find_root_by_empty_name
    assert_equal(@root, Directory.root)
    assert_equal("", Directory.root.name)
  end

  def test_should_find_root_by_lookup
    assert_equal(@root, Directory.lookup([]))
  end

  def test_should_create_root_as_needed
    Directory.delete_all
    assert_equal("", Directory.root.name)
  end

  def test_should_find_children
    assert_equal([@etc, @usr], Directory.root.children)
  end

  def test_should_evaluate_path
    assert_equal([], Directory.root.path)
    assert_equal(["usr"], @usr.path)
    assert_equal(["usr", "local"], @local.path)
  end

  def test_should_create_new_with_parents_as_needed
    Directory.delete_all

    back = Directory.lookup(["one", "step", "back"], true)
    assert_equal(["one", "step", "back"], back.path)
    assert_equal(4, Directory.find(:all).size)

    forward = Directory.lookup(["one", "step", "forward"], true)
    assert_equal(5, Directory.find(:all).size)

    assert_equal(forward.parent, back.parent)
  end

  def test_should_have_dirs_and_artifacts
    readme = @usr.artifacts.create(:name => "readme.txt")
    @usr.reload
    assert_equal([@local, readme], @usr.files)
  end
  
  def test_should_lookup_existing_directory
    mice = Directory.lookup(["three", "blind", "mice"], true)
    assert_equal(mice, Directory.lookup(["three", "blind", "mice"]))
  end

  def test_should_raise_exception_when_looking_up_nonexistant_directory
    assert_raise(Directory::NonExistant) do
      Directory.lookup(["three", "blind", "mice"])
    end
  end
  
end
