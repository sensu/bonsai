require 'spec_helper'

describe Api::V1::ExtensionsController do
  render_views

  let(:version)    { create :extension_version_with_config }
  let!(:extension) { version.extension }
  let!(:owner)     { extension.owner }
  let!(:user)      { create :user }
  let!(:admin)     { create :admin }
  
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
          source_asset_sha: build['asset_sha'],
          source_asset_url: build['asset_url'],
          source_sha_filename: build['sha_filename'],
          source_base_filename: build['base_filename'],
          source_asset_filename: build['asset_filename']
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

  describe 'GET #sync_repo' do
    subject do
      get :sync_repo,
          params: {id:       extension,
                   username: extension.owner_name},
          format: :json
    end

    it 'succeeds' do
      request.headers['X-Ops-Userid'] = owner.username
      subject
      data = JSON.parse(response.body)
      expect(response).to be_successful
      expect(data['message']).to eql(I18n.t("extension.syncing_in_progress"))
    end

    it 'succeeds when admin' do 
      request.headers['X-Ops-Userid'] = admin.username
      subject
      data = JSON.parse(response.body)
      expect(response).to be_successful
    end

    it 'fails authentication' do
      request.headers['X-Ops-Userid'] = user.username
      subject
      data = JSON.parse(response.body)
      expect(data['error_code']).to eql("UNAUTHORIZED")
    end

    it 'fails if not found' do 
      request.headers['X-Ops-Userid'] = admin.username
      get :sync_repo,
          params: {id:       '',
                   username: extension.owner_name},
          format: :json
      data = JSON.parse(response.body)
      expect(data['error_code']).to eql("NOT_FOUND")
    end

  end
end

