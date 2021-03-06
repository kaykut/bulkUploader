class CreateAdUnits < ActiveRecord::Migration
  def change
    create_table :ad_units do |t|
      t.string :dfp_id
      t.string :parent_id_dfp
      t.string :parent_id_bulk
      t.string :name
      t.string :description
      t.string :target_window
      t.string :target_platform
      t.boolean :explicitly_targeted
      t.integer :level
      
      t.timestamps
    end
  end
end
