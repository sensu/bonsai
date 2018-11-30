class AddConfigToExtensionVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :extension_versions, :config, :jsonb, default: {}
    add_index :extension_versions, :config, using: :gin
  end
end
