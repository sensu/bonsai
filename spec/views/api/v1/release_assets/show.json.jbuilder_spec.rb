require 'spec_helper'

describe 'api/v1/release_assets/show' do
  let(:extension) { create :extension }
  let(:version)  { create :extension_version_with_config, extension: extension }
  
  before do
    extension.tags << Tag.new(name: 'label')
    version.config['builds'].each do |build|
      version.release_assets << build(:release_asset,
        platform: build['platform'],
        arch: build['arch'],
        viable: build['viable'],
        source_asset_sha: build['asset_sha'],
        source_asset_url: build['asset_url'],
        source_sha_filename: build['sha_filename'],
        source_base_filename: build['base_filename'],
        source_asset_filename: build['asset_filename']
      )
    end
    @asset = version.release_assets.first
    assign(:release_asset, @asset)
    render
  end

  it "sets the type to Asset" do
    expect(json_body['type']).to eql("Asset")
  end

  it "serializes the extension name" do
    expect(json_body['metadata']['name']).to eql(version.extension.name)
  end

  it "serializes the url" do
    expect(json_body['spec']['url']).to eql(@asset.source_asset_url)
  end

  it "serializes the sha" do
    expect(json_body['spec']['sha512']).to eql(@asset.source_asset_sha)
  end

  it "serializes the namespace" do
    expect(json_body['metadata']['namespace']).to eql(@asset.extension_namespace)
  end

  it "includes extension labels" do
    expect(json_body['metadata']['labels']).to eql(@asset.extension.tags.map(&:name))
  end

  it "includes annotations" do
    expect(json_body['metadata']['annotations']).to eq({})
  end
end
