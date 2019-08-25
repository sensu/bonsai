require 'spec_helper'
include Annotations

describe 'api/v1/release_assets/show' do
  let(:extension) { create :extension }
  let(:version)  { create :extension_version_with_config, extension: extension }
  
  before do

    version.config['builds'].each do |build|
      version.release_assets << build(:release_asset,
        platform: build['platform'],
        arch: build['arch'],
        viable: build['viable'],
        source_asset_sha: build['asset_sha'],
        source_asset_url: build['asset_url'],
        source_sha_filename: build['sha_filename'],
        source_base_filename: build['base_filename'],
        source_asset_filename: build['asset_filename'],
        vanity_url: "https://s3.us-west-2.amazonaws.com"
      )
    end
    @asset = version.release_assets.first
    assign(:release_asset, @asset)
  end

  it "sets the type to Asset" do
    render
    expect(json_body['type']).to eql("Asset")
  end

  it 'sets the api version' do
    render
    expect(json_body['api_version']).to eql('core/v2')
  end

  it "serializes the extension name" do
    render
    expect(json_body['metadata']['name']).to eql("#{@asset.extension_name}_#{@asset.platform}_#{@asset.arch}")
  end

  it "returns null if no extension labels" do
    render
    expect(json_body['metadata']['labels']).to eql(nil)
  end

  it "serializes the url" do
    render
    expect(json_body['spec']['url']).to eql(@asset.vanity_url)
  end

  it "serializes the sha" do
    render
    expect(json_body['spec']['sha512']).to eql(@asset.source_asset_sha)
  end

end
