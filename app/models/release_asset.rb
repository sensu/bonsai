class ReleaseAsset < ApplicationRecord

  belongs_to :extension_version, required: false # asset should remain even if version is destroyed

  serialize :filter
  serialize :annotations, Hash

  delegate :extension,           to: :extension_version, allow_nil: true
  delegate :extension_name,      to: :extension_version, allow_nil: true
  delegate :extension_namespace, to: :extension_version, allow_nil: true
  delegate :owner_name,          to: :extension_version, allow_nil: true
  delegate :version,             to: :extension_version, allow_nil: true

  before_validation :update_annotations

  def viable?
    viable
  end

  def destination_pathname
    "#{commit_sha}/#{source_asset_filename}"
  end

  private 

  def update_annotations
    if extension && extension.hosted? && self.annotations['bonsai.sensu.io.message'].blank?
      self.annotations['bonsai.sensu.io.message'] = "This asset is for users with a valid Enterprise license"
    end
  end

end
