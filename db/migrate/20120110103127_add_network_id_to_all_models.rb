class AddNetworkIdToAllModels < ActiveRecord::Migration
  def change
    add_column :companies, :network_id, :integer
    add_column :ad_units, :network_id, :integer
    add_column :labels, :network_id, :integer
    add_column :ad_unit_sizes, :network_id, :integer
  end
end
