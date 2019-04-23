# Given an extension_version, this service class will save assets to a file store.
class PersistAssets
  include Interactor

  delegate :version, to: :context
  
  before :initialize_s3_bucket

  def call
  	context.fail!(error: "Do not store assets for master version") if version.version == 'master'
  	context.fail!(error: "#{version.version} has no config") if version.config.blank?
  	context.fail!(error: "#{version.version} has no builds in config") if version.config['builds'].blank?
  	
  	puts "Copying assets for #{version.version} to S3"

    version.config['builds'].each do |build|

      if build['asset_url'].blank?
        puts "**** Error in Source URL: #{build['asset_url']}"
        next
      end

      result = FindOrCreateReleaseAsset.call(version: version, build: build)
      context.fail!(error: "#{version.version} could not find or create release asset") if result.fail?
      release_asset = result.release_asset


      begin
        url = URI(release_asset.source_asset_url)
      rescue URI::Error => error
        puts "******** URI error: #{release_asset.source_asset_url} - #{error.message}"
        next
      end

      key = release_asset.destination_pathname

      object_exists = context.s3_bucket.object(key).exists?


      if object_exists
        puts "Already on S3: #{key}" 
      else
        # get file contents
        begin
          file = url.open
        rescue OpenURI::HTTPError => error
          status = error.io.status[0]
          message = error.io.status[1]
          puts "****** file read error: #{status} - #{message}"
          next
        end

      end
     
      begin
        unless object_exists
          context.s3_bucket.object(key).put(body: file, acl: 'public-read')
          puts "S3 success: #{key}"
        end
        uri = URI(context.s3_bucket.object(key).public_url)
        last_modified = context.s3_bucket.object(key).last_modified
      rescue Aws::S3::Errors::ServiceError => error 
        puts "****** S3 error: #{error.code} - #{error.message}"
        next
      end

      if ENV['AWS_S3_VANITY_HOST'].present?
        # replace the entire host
        uri.host = ENV['AWS_S3_VANITY_HOST']
        # remove the bucket from the path if returned in that format
        uri.path.gsub!(/staging.assets.bonsai.sensu.io\//, '')
        puts "******** Updating vanity_url: #{uri.to_s}"
      end
      release_asset.update_columns(vanity_url: uri.to_s, last_modified: last_modified)

    end # builds.each  	

  end

  private

  def initialize_s3_bucket
  	s3 = Aws::S3::Resource.new(
      access_key_id: ENV['AWS_S3_KEY_ID'],
      secret_access_key: ENV['AWS_S3_ACCESS_KEY'],
      region: ENV['AWS_S3_REGION']
    )

    context.s3_bucket = s3.bucket(ENV['AWS_S3_ASSETS_BUCKET'])

    begin
    	unless context.s3_bucket.exists?
    		message = "S3 error: #{ENV['AWS_S3_ASSETS_BUCKET']} bucket not found"
      	raise RuntimeError.new(message)
      	message.fail!(error: message)
      end
    rescue
    	message = "S3 error: network connection to S3 failed"
      raise RuntimeError.new(message)
      context.fail!(error: message)
    end

  end # initialize bucket


end