class CreateCompaniesLabelsJoinTable < ActiveRecord::Migration
  def up
  	create_table :companies_labels, :id => false do|t|
  		t.integer :company_id
  		t.integer :label_id
  	end
  end

  def down
  	drop_table :companies_labels
  end
end
