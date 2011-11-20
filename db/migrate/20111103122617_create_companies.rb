class CreateCompanies < ActiveRecord::Migration
  def change
    create_table :companies do |t|
      t.string :name
      t.string :company_type
      t.text :address
      t.string :email
      t.string :faxPhone
      t.string :primaryPhone
      t.string :DFPId
      t.text :comment
      t.boolean :enableSameAdvertiserCompetitiveExclusion

      t.timestamps
    end
  end
end

