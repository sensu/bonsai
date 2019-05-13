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

  describe 'GET #index' do
    subject do
      get :index,
          format: :json
    end

    it 'succeeds' do
      subject
      expect(response).to be_successful
    end

    it 'returns the proper data' do
      subject
      data = JSON.parse(response.body)
      expect(data["total"]).to be >= 1
    end
  end

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

  describe 'PUT #update' do
    let!(:user) { create(:admin) }

    context 'when a user is not authorized' do
      subject do
        request.headers.merge!({'X-Ops-Userid' => 'unauthorized'})
        put :update,
          params: {id:       extension,
                   username: extension.owner_name},
          format: :json
      end

      it 'responds with a 401' do
        subject
        expect(response.status.to_i).to eql(401)
        expect(response.body).to include("Could not find user")
      end
    end

    context 'when a user is authorized' do
      subject do
        request.headers.merge!({'X-Ops-Userid' => user.username})
        put :update,
          params: {id:       extension,
                   username: extension.owner_name,
                    extension: {
                      tag_tokens: 'larry, moe, curly',
                    }
                  },
          format: :json
      end
      it 'succeeds' do
        subject
        expect(response).to be_successful
        extension.reload
        expect(extension.tags.map(&:name)).to include('curly')
      end
    end

  end
end
