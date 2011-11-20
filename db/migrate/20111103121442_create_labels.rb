class CreateLabels < ActiveRecord::Migration
  def change
    create_table :labels do |t|
      t.string :name
      t.string :description
      t.string :label_type

      t.timestamps
    end
  end
end

