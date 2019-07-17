class DestroyAssetsWorker < ApplicationWorker

  def perform(version_id)
    @version = ExtensionVersion.find_by(id: version_id)
    raise RuntimeError.new("Version ID: #{version_id} not found.") unless @version
    DestroyAssets.call(version: @version)
  end

end