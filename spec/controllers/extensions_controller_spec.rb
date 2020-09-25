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

  describe "index" do
    it "succeeds" do
      get :index
      expect(response).to be_successful
    end

    context "with the archs filter" do
      render_views

      let(:viable)            { true }
      let(:arch)              { 'my-arch' }
      let(:arch2)             { 'other-arch' }
      let(:config)            do
        {'builds' => [
          {"viable" => viable,
           "arch"   => arch},
        ]}
      end
      let(:extension_version) { create :extension_version, config: config }
      let!(:extension)        { extension_version.extension }

      it "includes matching results" do
        expect(extension.name).to be_present

        get :index, params: {archs: [arch]}
        expect(response.body).to include(extension.name)
      end

      it "excludes non-matching results" do
        expect(extension.name).to be_present

        get :index, params: {archs: [arch2]}
        expect(response.body).to_not include(extension.name)
      end

      context "non-viable results" do
        let(:viable) { false }

        it "excludes non-viable results" do
          expect(extension.name).to be_present
          get :index, params: {archs: [arch2]}
          expect(response.body).to_not include(extension.name)
        end
      end
    end

    context "with the platforms filter" do
      render_views

      let(:viable)            { true }
      let(:plat)              { 'my-plat' }
      let(:plat2)             { 'other-plat' }
      let(:config)            do
        {'builds' => [
          {"viable" => viable,
           "platform"   => plat},
        ]}
      end
      let(:extension_version) { create :extension_version, config: config }
      let!(:extension)        { extension_version.extension }

      it "includes matching results" do
        expect(extension.name).to be_present

        get :index, params: {platforms: [plat]}
        expect(response.body).to include(extension.name)
      end

      it "excludes non-matching results" do
        expect(extension.name).to be_present

        get :index, params: {platforms: [plat2]}
        expect(response.body).to_not include(extension.name)
      end

      context "non-viable results" do
        let(:viable) { false }

        it "excludes non-viable results" do
          expect(extension.name).to be_present

          get :index, params: {platforms: [plat2]}
          expect(response.body).to_not include(extension.name)
        end
      end
    end

    describe 'suggested asset url' do
      render_views
      let(:extension_version) { create :extension_version, config: config }
      let!(:extension)        { extension_version.extension }
      it 'displays a link' do

        extension_version.update_attribute(:annotations, 
          {'io.sensu.bonsai.suggested_asset_url' => '/suggested/asset', 
            'io.sensu.bonsai.suggested_message' => 'Suggested Message' }
        )
        extension.reload
        get :show, params: {username: extension.owner_name, id: extension.lowercase_name}
        expect(response).to be_successful
        expect(response.body).to match /Suggested Message/im
      end
    end

  end

  describe "collections" do
    let(:collection) {create(:collection)}
    let(:extension) {create(:extension)}
    it 'succeeds' do
      extension.collections << collection
      get :collections
      expect(response.status).to eq(200)
    end
  end

  describe "sync_repo" do

    before do 
      allow(CompileExtension).to receive(:call).and_return(
        double(Interactor::Context, success?: :success)
      )
    end
    it 'redirects to the extension page' do
      put :sync_repo, params: params
      expect(response).to redirect_to [extension, username: extension.owner_name]
    end

    it 'starts a sync job' do
      expect(CompileExtension).to receive(:call)
      put :sync_repo, params: params
    end
  end

  describe "deprecate" do
    context "with a replacement" do
      let(:extension) { create :extension }
      let(:replacement_extension) { create :extension }
      let(:params){{
        id:       extension.lowercase_name,
        username: extension.owner_name,
        extension: {
          replacement:  "#{replacement_extension.owner_name},#{replacement_extension.lowercase_name}"
        }
      }}

      it "succeeds" do
        put :deprecate, params: params
        expect(response.redirect?).to be_truthy
        expect(response.status).to eq(302)
      end
    end
  end

end
