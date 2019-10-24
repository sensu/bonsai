require 'rails_helper'

RSpec.describe CollectionsController, type: :controller do

	let(:user) { create(:admin) }

  before do
    sign_in user
  end

  let(:valid_attributes) {
    {title: 'Test Title'}
  }

  let(:invalid_attributes) {
    {title: nil}
  }

  describe "GET #index" do
    it "returns a success response" do
      collection = create(:collection)
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Collection" do
        expect {
          post :create, params: {collection: valid_attributes}
        }.to change(Collection, :count).by(1)
      end

      it "redirects to the collections list" do
        post :create, params: {collection: valid_attributes}
        expect(response).to redirect_to(collections_url)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {collection: invalid_attributes}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {title: 'NEW TITLE', description: 'NEW DESCRIPTION'}
      }

      it "updates the requested tier" do
        collection = create(:collection, valid_attributes)
        put :update, params: {id: collection.id, collection: new_attributes}
        collection.reload
        expect(collection.title).to eq('NEW TITLE')
       	expect(collection.slug).to eq('test-collection')
        expect(collection.description).to eq('NEW DESCRIPTION')
      end

      it "redirects to the tiers list" do
        collection = create(:collection, valid_attributes)
        put :update, params: {id: collection.id, collection: new_attributes}
        expect(response).to redirect_to(collections_url)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        collection = create(:collection, valid_attributes)
        put :update, params: {id: collection.id, collection: invalid_attributes}
debugger
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested tier" do
      collection = create(:collection, valid_attributes)
      expect {
        delete :destroy, params: {id: collection.id}
      }.to change(Collection, :count).by(-1)
    end

    it "redirects to the tiers list" do
      collection = create(:collection, valid_attributes)
      delete :destroy, params: {id: collection.id}
      expect(response).to redirect_to(collections_url)
    end
  end
end
