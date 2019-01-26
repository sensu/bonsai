class AddCompilationErrorToExtensionVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :extension_versions, :compilation_error, :string
  end
end
