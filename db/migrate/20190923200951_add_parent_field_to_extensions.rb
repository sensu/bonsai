class AddParentFieldToExtensions < ActiveRecord::Migration[5.2]
  def change
  	add_column :extensions, :parent_id, :bigint
  	add_column :extensions, :parent_name, :string
  	add_column :extensions, :parent_owner_name, :string
  	add_index :extensions, :parent_id
  	add_index :extensions, [:parent_owner_name, :parent_name]
  end
end
