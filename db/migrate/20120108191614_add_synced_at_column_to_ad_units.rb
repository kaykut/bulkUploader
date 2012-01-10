class AddSyncedAtColumnToAdUnits < ActiveRecord::Migration
  def change
    add_column :ad_units, :synced_at, :timestamp
  end
end
