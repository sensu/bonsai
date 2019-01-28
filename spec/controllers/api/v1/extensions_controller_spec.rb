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