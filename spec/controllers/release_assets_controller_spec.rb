require 'spec_helper'

describe ReleaseAssetsController do
  render_views

  describe 'GET #download' do
    let(:platform) { "linux" }
    let(:arch)     { "x86_64" }
    let(:config)   { {"builds" =>
                        [{"arch"           => arch,
                          "filter"         =>
                            ["System.OS == linux",
                             "(System.Arch == x86_64) || (System.Arch == amd64)"],
                          "platform"       => platform,
                          "sha_filename"   => "test_asset-\#{version}-linux-x86_64.sha512.txt",
                          "asset_filename" => "test_asset-\#{version}-linux-x86_64.tar.gz",
                          "viable"         => true,
                          "asset_url"      => "https://example.com/download",
                          "asset_sha"      => "c1ec2f493f0ff9d83914c1ec2f493f0ff9d83914"}]} }
    let!(:version) { create :extension_version, config: config }

    it 'succeeds' do
      get :download,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to be_a(Hash)
    end

    it 'returns a file attachment' do
      get :download,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response.headers['Content-Disposition']).to match /attachment;/
      expect(response.headers['Content-Disposition']).to match /filename=/
    end

    it 'returns a JSON stream' do
      get :download,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      streamed_data = JSON.parse(response.stream.body)
      expect(streamed_data).to be_a(Hash)
      expect(streamed_data.keys).to include 'api_version'
    end
  end
end
