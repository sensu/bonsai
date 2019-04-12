require 'spec_helper'

describe Api::V1::ReleaseAssetsController do
  render_views

  describe 'GET #show' do
    let(:platform) { "debian" }
    let(:arch)     { "amd64" }
    
    let!(:version) { create :extension_version_with_config }

    before do 
      version.config['builds'].each do |build|
        version.release_assets << build(:release_asset,
          platform: build['platform'],
          arch: build['arch'],
          viable: build['viable'],
          github_asset_sha: build['asset_sha'],
          github_asset_url: build['asset_url'],
          github_sha_filename: build['sha_filename'],
          github_base_filename: build['base_filename'],
          github_asset_filename: build['asset_filename']
        )
      end
    end

    it 'succeeds' do
      get :show,
          params: {id:       version.extension,
                   username: version.extension.owner_name,
                   version:  version,
                   platform: platform,
                   arch:     arch},
          format: :json
      expect(response).to be_successful
      data = JSON.parse(response.body)
      expect(data).to be_a(Hash)
      expect(data['spec']).to be_a(Hash)
    end
  end
end
