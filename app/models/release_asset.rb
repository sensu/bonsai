class ReleaseAsset < ApplicationRecord

  belongs_to :extension_version, required: false # asset should remain even if version is destroyed

  serialize :filter
  serialize :annotations, Hash

  delegate :extension,           to: :extension_version, allow_nil: true
  delegate :extension_name,      to: :extension_version, allow_nil: true
  delegate :extension_namespace, to: :extension_version, allow_nil: true
  delegate :owner_name,          to: :extension_version, allow_nil: true
  delegate :version,             to: :extension_version, allow_nil: true

  def viable?
    viable
  end

  def destination_pathname
    "#{commit_sha}/#{source_asset_filename}"
  end

  def labels
    extension.tags.map(&:name)
  end

end
