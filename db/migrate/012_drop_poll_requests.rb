class DropPollRequests < ActiveRecord::Migration
  def self.up
    drop_table :poll_requests
    add_column :projects, :polling_needed, :boolean, :default=>false
    add_column :projects, :build_on_new_revisions, :boolean, :default=>true
    remove_column :projects, :lock_time
  end

  def self.down
  end
end
