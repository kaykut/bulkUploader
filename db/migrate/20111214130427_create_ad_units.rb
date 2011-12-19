class CreateAdUnits < ActiveRecord::Migration
  def change
    create_table :ad_units do |t|
      t.string :DFP_id
      t.string :parent_id_dfp
      t.string :parent_id_bulk
      t.string :name
      t.string :description
      t.string :target_window
      t.boolean :explicitly_targeted

      t.timestamps
    end
  end
end
