class AddIndexesToTables < ActiveRecord::Migration
  def change
    add_index :companies, :network_id
    add_index :companies, [:network_id, :name, :company_type], :unique => true
    add_index :companies, [:network_id, :dfp_id]
    
    add_index :ad_units, :network_id
    add_index :ad_units, :parent_id_bulk
    add_index :ad_units, [:network_id, :parent_id_dfp]
    add_index :ad_units, [:parent_id_bulk, :name]
    
    add_index :ad_unit_sizes_ad_units, :ad_unit_id
    
    add_index :labels, :network_id
    add_index :labels, [:network_id, :name]
    
    add_index :uploads, :network_id
  end
end
