require 'spec_helper'

describe ExtensionsController do
  let(:extension) { create :extension }
  let(:params)    { {
    id:       extension.lowercase_name,
    username: extension.owner_name,
  } }

  before do
    sign_in create(:admin)
  end

  describe "sync_repo" do
    it 'redirects to the extension page' do
      put :sync_repo, params: params
      expect(response).to redirect_to [extension, username: extension.owner_name]
    end

    it 'starts a sync job' do
      expect(SyncExtensionRepoWorker).to receive(:perform_async)
      put :sync_repo, params: params
    end
  end
end
