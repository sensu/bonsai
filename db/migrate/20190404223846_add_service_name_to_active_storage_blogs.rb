class AddServiceNameToActiveStorageBlogs < ActiveRecord::Migration[5.2]
  def up
    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string
    end
  end
end
