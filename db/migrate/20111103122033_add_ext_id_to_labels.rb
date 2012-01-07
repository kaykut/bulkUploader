class AddExtIdToLabels < ActiveRecord::Migration
  def change
    add_column :labels, :dfpid, :integer
  end
end
