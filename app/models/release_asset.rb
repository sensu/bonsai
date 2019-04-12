class ReleaseAsset < ApplicationRecord

  belongs_to :extension_version, required: false # asset should remain even if version is destroyed

  delegate :extension,           to: :extension_version, allow_nil: true
  delegate :extension_name,      to: :extension_version, allow_nil: true
  delegate :extension_namespace, to: :extension_version, allow_nil: true
  delegate :owner_name,          to: :extension_version, allow_nil: true
  delegate :version,             to: :extension_version, allow_nil: true

  def viable?
    viable
  end

  def annotations
    {}.tap do |results|
      if extension.hosted?
        results['bonsai.sensu.io.message'] = "This asset is for users with a valid Enterprise license"
      end
    end
  end

  def destination_pathname
    "#{commit_sha}/#{github_asset_filename}"
  end

end
