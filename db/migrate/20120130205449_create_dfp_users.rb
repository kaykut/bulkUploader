class CreateDfpUsers < ActiveRecord::Migration
  def change
    create_table :dfp_users do |t|
      t.string :id
      t.string :name
      t.string :email
      t.string :role_name
      t.string :role_id
      t.integer :network_id

      t.timestamps
    end
  end
end
