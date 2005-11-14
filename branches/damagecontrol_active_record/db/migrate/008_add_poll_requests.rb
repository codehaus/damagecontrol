class AddPollRequests < ActiveRecord::Migration
  def self.up
    create_table :poll_requests do |t|
      t.column :scm_time,       :timestamp
      t.column :project_id,     :integer
    end
  end

  def self.down
    drop_table :poll_requests
  end
end
