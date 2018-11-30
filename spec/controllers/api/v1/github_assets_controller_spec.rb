require 'spec_helper'

describe Api::V1::GithubAssetsController do
  render_views

  describe 'GET #show' do
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
                          "asset_url"      => "https://example.com/download",
                          "asset_sha"      => "c1ec2f493f0ff9d83914c1ec2f493f0ff9d83914"}]} }
    let!(:version) { create :extension_version, config: config }

    it 'succeeds' do
      get :show,
          params: {id:       version.extension,
                   username: version.extension.owner_name,
                   version:  version,
                   platform: platform,
                   arch:     arch},
          format: :json
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to be_a(Hash)
    end
  end
end
