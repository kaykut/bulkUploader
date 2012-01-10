class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :company_type
      t.text :address
      t.string :email
      t.string :fax_phone
      t.string :primary_phone
      t.string :dfp_id
      t.text :comment
      t.string :credit_status
      t.boolean :enable_same_advertiser_competitive_exclusion

      t.timestamps
    end
  end
end

