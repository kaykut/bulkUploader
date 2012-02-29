class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.string :name
      t.string :location
      t.string :datatype
      t.string :filename
      t.boolean :imported
      t.string :errors_file
      t.string :status

      t.timestamps
    end
  end
end
