class AlterExtensionsOwnerName < ActiveRecord::Migration[5.2]
  def change
    enable_extension :citext
    change_column :extensions, :owner_name, :citext
  end
end
