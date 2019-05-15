class MoveAnnotationsToVersion < ActiveRecord::Migration[5.2]
  def change
  	remove_column :release_assets, :annotations, :text
  	add_column :extension_versions, :annotations, :text
  end
end
