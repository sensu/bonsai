class RemoveUniqueIndexOnExtensionsLowercaseName < ActiveRecord::Migration[5.2]
  def up
    remove_index :extensions, name: "index_extensions_on_lowercase_name"
    add_index :extensions, ["lowercase_name"], name: "index_extensions_on_lowercase_name", unique: false
  end

  def down
    remove_index :extensions, name: "index_extensions_on_lowercase_name"
    add_index :extensions, ["lowercase_name"], name: "index_extensions_on_lowercase_name", unique: true
  end
end
