# Given an extension_version, this service class will save assets to a file store.
class PersistAssets
  include Interactor
  include InitializeS3

  delegate :version, to: :context

  def call
  	context.fail!(error: "Do not store assets for master version") if version.version == 'master'
  	context.fail!(error: "#{version.version} has no config") if version.config.blank?
  	context.fail!(error: "#{version.version} has no builds in config") if version.config['builds'].blank?

    version.config['builds'].each do |build|

      if build['asset_url'].blank?
        puts "**** Error in Source URL: #{build['asset_url']}"
        next
      end

      result = FindOrCreateReleaseAsset.call(version: version, build: build)
      context.fail!(error: "#{version.version} could not find or create release asset") if result.fail?
      release_asset = result.release_asset

      begin
        #puts "******** URI #{release_asset.source_asset_url}"
        url = URI(release_asset.source_asset_url)
      rescue URI::Error => error
        puts "******** URI error: #{release_asset.source_asset_url} - #{error.message}"
        next
      end

      key = release_asset.destination_pathname

      object_exists = s3_bucket.object(key).exists?

      if object_exists
        # we need to replace the file each iteration in order
        # to update files in case they were changed.
        begin
          s3_bucket.object(key).delete
          puts "Removed file from S3: #{key}"
        rescue Aws::S3::Errors::ServiceError => error 
          puts "****** S3 error: #{error.code} - #{error.message}"
        end
      end 

      # get file contents
      begin
        file = url.open
      rescue OpenURI::HTTPError => error
        status = error.io.status[0]
        message = error.io.status[1]
        puts "****** file read error: #{status} - #{message}"
        next
      end
     
      begin
        s3_bucket.object(key).put(body: file, acl: 'public-read')
        puts "File saved to S3: #{key}"
        uri = URI(s3_bucket.object(key).public_url)
        last_modified = s3_bucket.object(key).last_modified
      rescue Aws::S3::Errors::ServiceError => error 
        puts "****** S3 error: #{error.code} - #{error.message}"
        next
      end

      if ENV['AWS_S3_VANITY_HOST'].present?
        # replace the entire host
        uri.host = ENV['AWS_S3_VANITY_HOST']
        # remove the bucket from the path if returned in that format
        # note that this does not change the host
        uri.path.gsub!(/#{ENV['AWS_S3_ASSETS_BUCKET']}\//, '')
        puts "******** Updating vanity_url: #{uri.to_s}"
      end
      release_asset.update_columns(vanity_url: uri.to_s, last_modified: last_modified)

    end # builds.each

  end

  private

  def s3_bucket
    @_s3_bucket ||= begin
                      puts "Copying assets for #{version.version} to S3"
                      initialize_s3_bucket(context)
                    end
  end

end
