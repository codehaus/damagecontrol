class EnsureRootDir < ActiveRecord::Migration
  def self.up
    # Root directories were not created in the previous revision/migration. Fix it now.
    ScmFile.find(:all, :conditions => "parent_id IS NULL").each do |file|
      file.ensure_parent_exists!
      file.save
    end
  end

  def self.down
  end
end
