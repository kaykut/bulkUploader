class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :password
      t.integer :network_id
      t.string :environment

      t.timestamps
    end
  end
end
