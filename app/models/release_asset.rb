class ReleaseAsset < OpenStruct
  include ActiveModel::Conversion   # Needed for JBuilder serialization

  delegate :extension,           to: :version, allow_nil: true
  delegate :extension_name,      to: :version, allow_nil: true
  delegate :extension_namespace, to: :version, allow_nil: true
  delegate :owner_name,          to: :version, allow_nil: true

  def version_name
    version&.version
  end

  def viable?
    viable
  end

  def annotations
    {}.tap do |results|
      if version.hosted?
        results['bonsai.sensu.io.message'] = "This asset is for users with a valid Enterprise license"
      end
    end
  end
end
