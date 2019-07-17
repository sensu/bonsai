# Given an extension_version, this service class will save assets to a file store.
class DestroyAssets
  include Interactor
  include InitializeS3

  delegate :version, to: :context
  
  before :initialize_s3_bucket

  def call
  	context.fail!(error: "It does not store assets for master version") if version.version == 'master'
  	
  	puts "Destroying assets for #{version.version} on S3"

    version.release_assets.each do |release_asset|

      key = release_asset.destination_pathname

      object_exists = context.s3_bucket.object(key).exists?

      begin
        if object_exists
          context.s3_bucket.object(key).delete
          puts "S3 destroyed: #{key}"
        else
          puts "Already deleted from S3: #{key}" 
        end
        release_asset.destroy
      rescue Aws::S3::Errors::ServiceError => error 
        puts "****** S3 error: #{error.code} - #{error.message}"
        next
      end

    end # release_assets.each

  end

end