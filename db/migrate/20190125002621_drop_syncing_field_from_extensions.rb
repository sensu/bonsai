class DropSyncingFieldFromExtensions < ActiveRecord::Migration[5.2]
  def change
  	remove_column :extensions, :syncing, :boolean, default: false
  end
end
