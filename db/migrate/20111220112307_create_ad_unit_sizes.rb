class CreateAdUnitSizes < ActiveRecord::Migration
  def change
    create_table :ad_unit_sizes do |t|
      t.integer :height
      t.integer :width
      t.boolean :is_aspect_ratio
      t.string :environment_type

      t.timestamps
    end
  end
end
