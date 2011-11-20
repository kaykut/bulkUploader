class AddExtIdToLabels < ActiveRecord::Migration
  def change
    add_column :labels, :DFPid, :integer
  end
end
