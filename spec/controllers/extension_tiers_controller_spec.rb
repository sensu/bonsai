require 'spec_helper'

describe ExtensionTiersController do
  let(:user)      { create(:admin) }
  let(:tier)      { create :tier, rank: 200 }
  let(:extension) { create :extension }

  before do
    Tier.destroy_all
    sign_in user
    create :tier, rank: 5    # default tier
  end

  describe "PUT #update" do
    it "updates the requested extension" do
      put :update, params: {id: tier.to_param, username: extension.owner_name, extension_id: extension.to_param}
      extension.reload
      expect(extension.tier).to eq tier
    end

    it "redirects to the extension" do
      put :update, params: {id: tier.to_param, username: extension.owner_name, extension_id: extension.to_param}
      expect(response).to redirect_to [extension, username: extension.owner_name]
    end
  end
end
