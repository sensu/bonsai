class PersistAssetsWorker < ApplicationWorker

  def perform(version_id)
    @version = ExtensionVersion.find_by(id: version_id)
    raise RuntimeError.new("Version ID: #{version_id} not found.") unless @version
    PersistAssets.call(version: @version)
  end

end