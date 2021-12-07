require 'active_support/concern'

module InitializeS3
  extend ActiveSupport::Concern

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
       context.fail!(error: message)
      end
    rescue
    	message = "S3 error: network connection to S3 failed"
      raise RuntimeError.new(message)
      context.fail!(error: message)
    end

  end # initialize bucket
end