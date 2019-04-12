require 'spec_helper'

describe Api::V1::ExtensionsController do
  render_views

  let(:version)    { create :extension_version_with_config }
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
      expect(data['versions'][0]['assets'].length).to eql(2)
    end
  end
end
