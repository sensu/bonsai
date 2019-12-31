class AddPrivateToExtension < ActiveRecord::Migration[5.2]
  def change
  	change_column :extensions, :privacy, :boolean, default: false 
  	add_index :extensions, :privacy
  end
end
