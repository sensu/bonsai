require 'spec_helper'

describe AccountsController do
  let(:user) { create(:user) }
  before { sign_in user }

  describe 'POST #create' do
    before do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:github]
    end

    it 'creates a new account for a user' do
      pending
      expect do
        post :create, params: {provider: 'github'}
      end.to change(user.accounts, :count).by(1)
    end

    it 'redirects to the user profile on success by default' do
      post :create, params: {provider: 'github'}
      pending
      expect(response).to redirect_to(edit_profile_path)
    end

    it 'redirects to the stored location for the user on success if set' do
      controller.store_location!("http://www.google.com")

      post :create, params: {provider: 'github'}
      pending
      expect(response).to redirect_to("http://www.google.com")
    end
  end

  describe 'DELETE #destroy' do
    let!(:account) { create(:account, user: user) }

    it 'destroys an account for a user' do
      request.env['HTTP_REFERER'] = 'http://example.com/back'
      pending
      expect { delete :destroy, params: { id: account.id, user_id: user.id } }
      .to change(user.accounts, :count).by(-1)
    end
  end
end
