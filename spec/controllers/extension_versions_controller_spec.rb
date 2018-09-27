require 'spec_helper'

describe ExtensionVersionsController do
  include ExtensionVersionsHelper

  let(:extension_version) { create :extension_version }
  let(:extension)         { extension_version.extension }

  before do
    sign_in create(:user)
  end

  describe "download" do
    it 'succeeds' do
      get :download, params: {username: extension.owner_name, extension_id: extension.lowercase_name, version: extension_version.version}

      expect(response).to redirect_to download_url_for(extension_version)
    end
  end
end
