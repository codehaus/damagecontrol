class DropBuildLogs < ActiveRecord::Migration
  def self.up
    drop_table :build_logs
    remove_column :builds, :stdout_id
    remove_column :builds, :stderr_id
  end

  def self.down
    add_column :builds, :stdout_id, :integer
    add_column :builds, :stderr_id, :integer

    create_table :build_logs do |t|
      t.column :data,               :text
    end
  end
end
