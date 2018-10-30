class AddReleaseNotesToExtensionVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :extension_versions, :release_notes, :text
  end
end
