class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table :artifacts do |t|
      t.column :relative_path,       :string
      t.column :is_primary,          :boolean
      t.column :build_id,            :integer
      t.column :position,            :integer
    end
    create_table :build_logs do |t|
      t.column :data,                :text
    end
    create_table :builds do |t|
      t.column :state,               :text
      t.column :pid,                 :integer
      t.column :exitstatus,          :integer
      t.column :reason,              :text
      t.column :env,                 :text
      t.column :command,             :text
      t.column :create_time,         :timestamp
      t.column :begin_time,          :timestamp
      t.column :end_time,            :timestamp
      t.column :stdout_id,           :integer
      t.column :stderr_id,           :integer
      t.column :revision_id,         :integer
      t.column :triggering_build_id, :integer
    end
    create_table :projects do |t|
      t.column :name,                :text
      t.column :home_page,           :text
      t.column :relative_build_path, :text
      t.column :lock_time,           :timestamp
      t.column :quiet_period,        :integer
      t.column :uses_polling,        :boolean
      t.column :build_command,       :text
      t.column :scm,                 :text
      t.column :publishers,          :text
      t.column :scm_web,             :text
      t.column :tracker,             :text
    end
    create_table :projects_projects do |t|
      t.column :depending_id,        :integer
      t.column :dependant_id,        :integer
    end
    create_table :revision_files do |t|
      t.column :status,              :text
      t.column :path,                :text
      t.column :previous_native_revision_identifier,    :text
      t.column :native_revision_identifier,             :text
      t.column :timepoint,           :timestamp
      t.column :revision_id,         :integer
    end
    create_table :revisions do |t|
      t.column :identifier,          :text
      t.column :developer,           :text
      t.column :message,             :text
      t.column :timepoint,           :timestamp
      t.column :project_id,          :integer
    end
  end

  def self.down
    raise "This is the initial schema"
  end
end
