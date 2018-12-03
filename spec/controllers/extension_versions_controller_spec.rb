require 'spec_helper'

describe ExtensionVersionsController do
  include ExtensionVersionsHelper

  let!(:extension_version) { create :extension_version }
  let(:extension)          { extension_version.extension }

  let(:params) { {
    extension_id: extension.lowercase_name,
    username:     extension.owner_name,
    version:      extension_version.version,
  } }

  before do
    sign_in create(:admin)
  end

  describe "download" do
    it 'succeeds' do
      get :download, params: params

      expect(response).to redirect_to download_url_for(extension_version)
    end
  end

  describe "new" do
    it "returns a success response" do
      get :new, params: params
      expect(response).to be_successful
    end
  end


  describe "create" do
    let(:params) { {
      extension_version: {version: version},
      extension_id:      extension.lowercase_name,
      username:          extension.owner_name,
    } }

    context "with valid params" do
      let(:version) { "1.2.#{rand 999_999}" }

      before :each do
        ExtensionVersion.destroy_all
        extension_version   # instantiate
      end

      it "creates a new extension version" do
        expect {
          post :create, params: params
          expect(response).to redirect_to [extension, username: extension.owner_name]
        }.to change{ExtensionVersion.count}.by(1)
      end

      it "sends notification emails" do
        expect(ExtensionNotifyWorker).to receive(:perform_async)
        post :create, params: params
      end
    end

    context "with invalid params" do
      let(:version) { nil }

      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: params
        expect(response).to be_successful
      end
    end
  end


  describe "destroy" do
    it "destroys the requested extension version" do
      expect {
        delete :destroy, params: params
      }.to change{ExtensionVersion.count}.by(-1)
    end

    it "redirects to the extension page" do
      delete :destroy, params: params
      expect(response).to redirect_to [extension, username: extension.owner_name]
    end
  end

  describe "download_asset_definition" do
    render_views

    it "returns a JS result" do
      get :download_asset_definition, params: params, xhr: true
      expect(response).to be_successful
      expect(response.content_type).to match /javascript/
    end

    it "returns HTML content" do
      get :download_asset_definition, params: params, xhr: true
      expect(response.body).to match /<div/
    end
  end
end
