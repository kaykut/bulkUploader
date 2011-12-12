class AddSyncedAtColumnToCompaniesAndLabels < ActiveRecord::Migration
  def change
    add_column :companies, :synced_at, :date
    add_column :labels, :synced_at, :date
  end
end
