require 'spec_helper'

RSpec.describe TiersController, type: :controller do
  let(:user) { create(:admin) }

  before do
    sign_in user
  end

  # This should return the minimal set of attributes required to create a valid
  # Tier. As you add validations to Tier, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    build_stubbed(:tier).attributes
  }

  let(:invalid_attributes) {
    {name: nil, rank: nil}
  }

  describe "GET #index" do
    it "returns a success response" do
      tier = Tier.create! valid_attributes
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      tier = Tier.create! valid_attributes
      get :show, params: {id: tier.to_param}
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Tier" do
        expect {
          post :create, params: {tier: valid_attributes}
        }.to change(Tier, :count).by(1)
      end

      it "redirects to the tiers list" do
        post :create, params: {tier: valid_attributes}
        expect(response).to redirect_to(tiers_url)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {tier: invalid_attributes}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {name: 'NEW NAME', rank: 69, icon_name: 'NEW ICON NAME'}
      }

      it "updates the requested tier" do
        tier = Tier.create! valid_attributes
        put :update, params: {id: tier.to_param, tier: new_attributes}
        tier.reload
        expect(tier.name).to eq      'NEW NAME'
        expect(tier.rank).to eq      69
        expect(tier.icon_name).to eq 'NEW ICON NAME'
      end

      it "redirects to the tiers list" do
        tier = Tier.create! valid_attributes
        put :update, params: {id: tier.to_param, tier: valid_attributes}
        expect(response).to redirect_to(tiers_url)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        tier = Tier.create! valid_attributes
        put :update, params: {id: tier.to_param, tier: invalid_attributes}
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested tier" do
      tier = Tier.create! valid_attributes
      expect {
        delete :destroy, params: {id: tier.to_param}
      }.to change(Tier, :count).by(-1)
    end

    it "redirects to the tiers list" do
      tier = Tier.create! valid_attributes
      delete :destroy, params: {id: tier.to_param}
      expect(response).to redirect_to(tiers_url)
    end
  end

end
