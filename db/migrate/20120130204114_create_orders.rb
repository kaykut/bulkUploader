class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :advertiser_id
      t.string :name
      t.string :trafficker_id
      t.string :sales_person_id
      t.string :agency_id
      t.string :external_order_id
      t.string :po_number
      t.integer :network_id
      t.text :notes
      
      t.timestamps
    end
  end
end
