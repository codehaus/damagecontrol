class AddBuildExecutor < ActiveRecord::Migration
  def self.up
    create_table :build_executors do |t|
      t.column :description,       :string
      t.column :is_master,         :boolean
    end

    create_table :build_executors_projects, :id => false do |t|
      t.column :build_executor_id, :integer
      t.column :project_id,        :integer
    end
    
    add_column :builds,   :build_executor_id, :integer
    add_column :projects, :local_build,       :boolean, :default => true
    
  end

  def self.down
    remove_column :projects, :local_build
    remove_column :builds,   :build_executor_id
    drop_table :build_executors_projects
    drop_table :build_executors
  end
end
