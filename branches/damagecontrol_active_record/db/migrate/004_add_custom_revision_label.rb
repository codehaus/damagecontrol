class AddCustomRevisionLabel < ActiveRecord::Migration
  def self.up
    add_column :projects, :initial_revision_label, :integer, :default=>1
    add_column :revisions, :position, :integer
  end

  def self.down
    remove_column :revisions, :position
    remove_column :projects, :initial_revision_label
  end
end
