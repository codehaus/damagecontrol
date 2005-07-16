require 'file_methods'

# A Directory is a directory in DamageControl's virtual filesystem.
# This filesystem is used for build artifacts. (It is not used for
# anything SCM related. See RevisionFile and Revision for that).
#
class Directory < ActiveRecord::Base
  acts_as_tree :order => "name"
  has_many :artifacts
  
  include FileMethods
  
  class NonExistant < StandardError
  end

  # The root of the file system  
  def self.root
    root = Directory.find_by_name("")
    if(root.nil?)
      root = Directory.create(:name => "")
    end
    root
  end

  # Looks up a directory represented by +path+, an array of strings
  # where each is a directory name. +path+ will be followed from the
  # root of the virtual file system. If the directory doesn't exist,
  # Directory::NonExistant will be thrown, unless +create+ is true,
  # in which case the directory will be created instead. 
  def self.lookup(path, create=false)
    dir = self.root
    parent = dir
    path.each do |name|
      dir = self.find_by_name_and_parent_id(name, parent.id)
      if(dir.nil?)
        if(create)
          dir = parent.children.create(:name => name)
        else
          raise NonExistant.new(path.join("/"))
        end
      end
      parent = dir
    end
    dir
  end
  
  def files
    children.dup + artifacts
  end
end
