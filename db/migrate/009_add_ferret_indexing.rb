class AddFerretIndexing < ActiveRecord::Migration
  def self.up
    add_column :revision_files, :indexed, :boolean
  end

  def self.down
    remove_column :revision_files, :indexed
  end
end
