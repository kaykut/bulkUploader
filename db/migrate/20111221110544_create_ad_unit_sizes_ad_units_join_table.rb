class CreateAdUnitSizesAdUnitsJoinTable < ActiveRecord::Migration
  def up
  	create_table :ad_unit_sizes_ad_units, :id => false do|t|
  		t.integer :ad_unit_id
  		t.integer :ad_unit_size_id
  	end
  end

  def down
  	drop_table :ad_unit_sizes_ad_units
  end
end
