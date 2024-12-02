class CreateFileUploads < ActiveRecord::Migration[7.1]
  def change
    create_table :file_uploads do |t|
      t.integer "admin_id"
      t.timestamps
    end
  end
end
