require 'spec_helper'

describe 'api/v1/github_assets/show' do
  let(:version)        { create :extension_version }
  let(:url)            { "http://example.com/asset" }
  let(:sha)            { "abcdef1234" }
  let!(:release_asset) { ReleaseAsset.new(version:   version,
                                         asset_url: url,
                                         asset_sha: sha) }

  before do
    assign(:release_asset, release_asset)
    render
  end

  it "sets the type to Asset" do
    expect(json_body['type']).to eql("Asset")
  end

  it "serializes the extension name" do
    expect(json_body['metadata']['name']).to eql(version.extension.name)
  end

  it "serializes the url" do
    expect(json_body['spec']['url']).to eql(url)
  end

  it "serializes the sha" do
    expect(json_body['spec']['sha512']).to eql(sha)
  end

  it "serializes the namespace" do
    expect(json_body['metadata']['namespace']).to eql('default')
  end
end
