class AddTrackingFilesToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :created_file, :string
    add_column :uploads, :not_created_file, :string
  end
end
