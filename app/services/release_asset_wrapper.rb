module ReleaseAssetWrapper

  def initialize
    s3 = Aws::S3::Resource.new(
      access_key_id: ENV['AWS_S3_KEY_ID'],
      secret_access_key: ENV['AWS_S3_ACCESS_KEY'],
      region: ENV['AWS_S3_REGION']
    )

    @s3_bucket = s3.bucket(ENV['AWS_S3_ASSETS_BUCKET'])
    begin
      raise RuntimeError.new("S3 error: #{ENV['AWS_S3_ASSETS_BUCKET']} bucket not found") unless @s3_bucket.exists?
    rescue
      raise RuntimeError.new("S3 error: network connection to S3 failed")
    end
    super
  end

  def persist_assets(version)
    return if version.blank? || version.version == 'master' || version.config.blank?

    unless version.config['builds'].present?
      puts "#{version.version} config builds not found"
      return
      #raise RuntimeError.new("Version ID: #{version.id} config builds not found")
    end

    puts "Copying assets for #{version.version} to S3"

    version.config['builds'].each do |build|

      if build['asset_url'].blank?
        puts "**** Error in Github URL: #{build['asset_url']}"
        next
      end

      release_asset = find_or_create_release_asset(version, build)

      begin
        url = URI(release_asset.github_asset_url)
      rescue URI::Error => error
        puts "******** URI error: #{release_asset.github_asset_url} - #{error.message}"
        next
      end

      key = release_asset.destination_pathname

      object_exists = @s3_bucket.object(key).exists?
      puts "Already on S3: #{key}" if object_exists
     
      begin
        unless object_exists
          url.open do |file|
            @s3_bucket.object(key).put(body: file, acl: 'public-read')
          end
          puts "S3 success: #{key}"
        end
        uri = URI(@s3_bucket.object(key).public_url)
        last_modified = @s3_bucket.object(key).last_modified
      rescue OpenURI::HTTPError => error
        status = error.io.status[0]
        message = error.io.status[1]
        puts "****** file read error: #{status} - #{message}"
        next
      rescue Aws::S3::Errors::ServiceError => error 
        puts "****** S3 error: #{error.code} - #{error.message}"
        next
      end

      if ENV['AWS_S3_VANITY_HOST'].present?
        uri.host = ENV['AWS_S3_VANITY_HOST'] 
        puts "******** Updating vanity_url: #{uri.host}"
      end
      release_asset.update_columns(vanity_url: uri.to_s, last_modified: last_modified)

    end # builds.each
  end # persist_assets

  private

  def find_or_create_release_asset(version, build)
  	release_asset = version.release_assets.find_by(
                          platform: build['platform'],
                          arch: build['arch'],
                          commit_sha: version.last_commit_sha)

    if !release_asset

      github_asset_filename = version.interpolate_variables(build['asset_filename'])
      github_sha_filename = version.interpolate_variables( build['sha_filename'])
      
      release_asset = ReleaseAsset.create(
        platform: build['platform'],
        arch: build['arch'],
        viable: build['viable'],
        filter: Array.wrap(build['filter']),
        commit_sha: version.last_commit_sha,
        commit_at: version.last_commit_at,
        github_asset_sha: build['asset_sha'],
        github_asset_url: build['asset_url'],
        github_sha_filename: github_sha_filename,
        github_base_filename: build['base_filename'],
        github_asset_filename: github_asset_filename
      )

      version.release_assets << release_asset
    end
   	release_asset
  end # find_or_create_release_asset

end