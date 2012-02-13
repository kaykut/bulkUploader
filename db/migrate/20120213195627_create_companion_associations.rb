class CreateCompanionAssociations < ActiveRecord::Migration
  def change
    create_table :companion_associations do |t|
      t.integer :ad_unit_size_id
      t.integer :companion_id

      t.timestamps
    end
  end
end
