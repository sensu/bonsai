# Given an extension version, this service class will find or create a release asset record.
class FindOrCreateReleaseAsset
  include Interactor

  # The required context attributes:
  delegate :version,  to: :context
  delegate :build, 		to: :context
  
  def call
    message = []
    message << "#{version.version} invalid build" if build.blank?
    message << "#{version.version} invalid platform" if build['platform'].blank?
    message << "#{version.version} invalid arch" if build['arch'].blank?
    context.fail!(error: message) if message.present? 

  	release_asset = version.release_assets.find_by(
  												commit_sha: version.last_commit_sha,
                          platform: build['platform'],
                          arch: build['arch'])

    context.release_asset = if release_asset.present?
      update_release_asset(release_asset, version, build)
    else
      create_release_asset(version, build)
    end
  end

  private

  def create_release_asset(version, build)
    release_asset = ReleaseAsset.create(
      platform: build['platform'],
      arch: build['arch'],
      viable: build['viable'],
      filter: Array.wrap(build['filter']),
      commit_sha: version.last_commit_sha,
      commit_at: version.last_commit_at,
      source_asset_sha: build['asset_sha'],
      source_asset_url: build['asset_url'],
      source_sha_filename: source_sha_filename(version, build),
      source_base_filename: build['base_filename'],
      source_asset_filename: source_asset_filename(version, build)
    )

    version.release_assets << release_asset
    release_asset
  end

  def update_release_asset(release_asset, version, build)
    release_asset.update(
      viable: build['viable'],
      filter: Array.wrap(build['filter']),
      commit_sha: version.last_commit_sha,
      commit_at: version.last_commit_at,
      source_asset_sha: build['asset_sha'],
      source_asset_url: build['asset_url'],
      source_sha_filename: source_sha_filename(version, build),
      source_base_filename: build['base_filename'],
      source_asset_filename: source_asset_filename(version, build)
    )
    release_asset
  end

  def source_asset_filename(version, build)
    version.interpolate_variables( build['asset_filename'] )
  end

  def source_sha_filename(version, build)
    version.interpolate_variables( build['sha_filename'] )
  end

end