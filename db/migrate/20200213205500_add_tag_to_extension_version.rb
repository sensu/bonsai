class AddTagToExtensionVersion < ActiveRecord::Migration[5.2]
  def up
    add_column :extension_versions, :tag, :string

    ExtensionVersion.all.each do |extension_version|
      extension_version.tag = extension_version.version
      extension_version.version = SemverNormalizer.call(extension_version.version)
      extension_version.save
    end
  end

  def down
    ExtensionVersion.all.each do |extension_version|
      extension_version.version = extension_version.tag
      extension_version.save
    end

    remove_column :extension_versions, :tag
  end
end
