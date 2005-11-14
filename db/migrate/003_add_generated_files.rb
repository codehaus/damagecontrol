class AddGeneratedFiles < ActiveRecord::Migration
  def self.up
    add_column :projects, :generated_files, :text
  end

  def self.down
    remove_column :projects, :generated_files
  end
end
