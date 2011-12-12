class AddTernalIdColumnToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :external_id, :string
  end
end
