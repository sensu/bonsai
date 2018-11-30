require 'spec_helper'

describe Api::V1::ExtensionsController do
  render_views

  let(:platform)   { "linux" }
  let(:arch)       { "x86_64" }
  let(:sha)        { "c1ec2f493f0ff9d83914c1ec2f493f0ff9d83914" }
  let(:config)     { {"builds" =>
                        [{"arch"           => arch,
                          "filter"         =>
                            ["System.OS == linux",
                             "(System.Arch == x86_64) || (System.Arch == amd64)"],
                          "platform"       => platform,
                          "sha_filename"   => "test_asset-\#{version}-linux-x86_64.sha512.txt",
                          "asset_filename" => "test_asset-\#{version}-linux-x86_64.tar.gz",
                          "asset_url"      => "https://example.com/download",
                          "asset_sha"      => sha}]} }
  let(:version)    { create :extension_version, config: config }
  let!(:extension) { version.extension }

  describe 'GET #show' do
    subject do
      get :show,
          params: {id:       extension,
                   username: extension.owner_name},
          format: :json
    end

    it 'succeeds' do
      subject
      expect(response).to be_successful
    end

    it 'returns the proper data' do
      subject
      data = JSON.parse(response.body)
      expect(data["builds"].first["asset_sha"]).to eql(sha)
    end
  end
end
