require "spec_helper"

describe PersistAssets do

  describe ".call" do

  	before do
      @s3_stubbed = true
  		s3 = Aws::S3::Resource.new(
        access_key_id: ENV['AWS_S3_KEY_ID'],
        secret_access_key: ENV['AWS_S3_ACCESS_KEY'],
        region: ENV['AWS_S3_REGION']
      )
      s3_bucket = s3.bucket(ENV['AWS_S3_ASSETS_BUCKET'])

      # trap incorrect ENV variables (Travis) or no network connection
      begin
        if s3_bucket.exists?
          @s3_stubbed = false
        else
          stub_aws
        end
      rescue
        stub_aws
      end
  	end
	
    context "when given valid config" do
      let(:version) { create(:extension_version_with_config ) }
      let(:build) { version.config['builds'][0] }
      subject(:context) { PersistAssets.call(version: version, build: build) }

      it "succeeds" do 
        expect(context).to be_a_success
      end

    end

    context "when given valid hosted config" do
      let(:extension) { create(:extension, :hosted) }
      let(:version) { create(:extension_version_with_hosted_config, extension: extension) }
      let(:build) { version.config['builds'][0] }
      subject(:context) { PersistAssets.call(version: version, build: build) }

      it "succeeds" do 
        expect(context).to be_a_success
      end

    end

	end

  def stub_aws
    Aws::S3::Resource.any_instance.stub_chain(:bucket, :exists?).and_return(true)
    Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :exists?).and_return(true)
    Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :public_url).and_return('https://s3.us-west-2.amazonaws.com/bucket/example.com')
    Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :last_modified).and_return(DateTime.now.to_s(:db))
  end
  
end