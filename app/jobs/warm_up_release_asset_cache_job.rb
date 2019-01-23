class WarmUpReleaseAssetCacheJob < ApplicationJob
  queue_as :default

  def perform(extension_version)
    return unless extension_version.source_file.attached?

    file_paths = extension_version.release_assets.map { |release_asset|
      extension_version.interpolate_variables(release_asset.asset_filename)
    }.find_all(&:present?)

    FetchHostedFile.bulk_cache(extension_version: extension_version, file_paths: file_paths)
  end
end
