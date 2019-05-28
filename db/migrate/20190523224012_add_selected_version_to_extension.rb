class AddSelectedVersionToExtension < ActiveRecord::Migration[5.2]
  def change
  	add_column :extensions, :selected_version_id, :bigint
  end
end
