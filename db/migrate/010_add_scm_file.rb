class AddScmFile < ActiveRecord::Migration
  def self.up
    create_table :scm_files do |t|
      t.column :path,            :text
      t.column :directory,       :boolean
      t.column :parent_id,       :integer
      t.column :project_id,      :integer
      t.column :scm_files_count, :integer
    end
    
    rename_table :revision_files, :revisions_scm_files
    add_column :revisions_scm_files, :scm_file_id, :integer

    # Migrate the contents
    rsfs = RevisionsScmFiles.find(:all)
    puts "Migrating #{rsfs.length} revision files to new database structure. Please be patient." unless rsfs.empty?
    rsfs.each do |rsf|
      STDOUT.write(".")
      STDOUT.flush
      scm_file = ScmFile.find_or_create_by_directory_and_path_and_project_id(false, rsf.path, rsf.revision.project_id)
      rsf.scm_file_id = scm_file.id
      rsf.save
    end
    puts "Done" unless rsfs.empty?

    remove_column :revisions_scm_files, :path
    remove_column :revisions_scm_files, :id
  end

  def self.down
    drop_table :scm_files
  end
end
