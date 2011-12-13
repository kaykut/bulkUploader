class AddSyncedAtColumnToCompaniesAndLabels < ActiveRecord::Migration
  def change
    add_column :companies, :synced_at, :timestamp
    add_column :labels, :synced_at, :timestamp
  end
end
