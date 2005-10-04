class AddPromotionLevel < ActiveRecord::Migration
  def self.up
    create_table :promotion_levels do |t|
      t.column :name, :string
    end
    PromotionLevel.create :name => "Ready for UAT"
    PromotionLevel.create :name => "Release"
    
    add_column :builds, :promotion_level_id, :integer
  end

  def self.down
    remove_column :builds, :promotion_level_id

    drop_table :promotion_levels
  end
end
