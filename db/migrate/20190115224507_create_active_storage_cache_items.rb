class CreateActiveStorageCacheItems < ActiveRecord::Migration[5.2]
  def change
    create_table :active_storage_cache_items do |t|
      t.string :key

      t.timestamps
    end
    add_index :active_storage_cache_items, :key
  end
end
