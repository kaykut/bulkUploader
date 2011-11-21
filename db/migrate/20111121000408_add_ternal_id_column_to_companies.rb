class AddTernalIdColumnToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :externalId, :string
  end
end
