# Given an extension_version, this service class will save assets to a file store.
class DestroyAssets
  include Interactor
  include InitializeS3

  delegate :version, to: :context

  def call
    context.fail!(error: "It does not store assets for master version") if version.version == 'master'

    if Rails.configuration.x.s3_mirroring
      version.release_assets.each(&method(:purge_s3_mirror))
    end
  end

  private

  def purge_s3_mirror(release_asset)
    key           = release_asset.destination_pathname
    object_exists = s3_bucket.object(key).exists?

    begin
      if object_exists
        s3_bucket.object(key).delete
        puts "S3 destroyed: #{key}"
      else
        puts "Already deleted from S3: #{key}"
      end
      release_asset.destroy
    rescue Aws::S3::Errors::ServiceError => error
      puts "****** S3 error: #{error.code} - #{error.message}"
      return
    end
  end

  def s3_bucket
    @_s3_bucket ||= begin
                      puts "Destroying assets for #{version.version} on S3"
                      initialize_s3_bucket(context)
                    end
  end

end
