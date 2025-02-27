require 'spec_helper'

describe SessionsController do
  before do
    User.destroy_all
  end

  describe 'POST #create' do
    let(:auth_hash) { OmniAuth.config.mock_auth[:github] }

    before do

      allow(User).to receive(:find_or_create_from_github_oauth).and_return( create(:user, id: 1) )
      request.env['omniauth.auth'] = auth_hash
    end

    it 'loads or creates the user from the OAuth hash' do
      expect(User).to receive(:find_or_create_from_github_oauth).with(auth_hash)
      post :create, params: {provider: 'github'}
    end

    it 'sets the session' do
      post :create, params: {provider: 'github'}
      expect(session[:user_id]).to eq(1)
    end

    it 'redirects to the root path' do
      post :create, params: {provider: 'github'}
      expect(response).to redirect_to(root_path)
    end

    it 'notifies the user they have signed in' do
      post :create, params: {provider: 'github'}
      expect(flash[:notice]).
        to eql(I18n.t('user.signed_in', name: 'John Doe'))
    end
  end

  describe 'DELETE #destroy' do
    it 'resets the session' do
      delete :destroy
      expect(session[:user_id]).to be_blank
    end

    it 'notifies the user they have signed out' do
      delete :destroy
      expect(flash[:notice]).
        to eql(I18n.t('user.signed_out'))
    end
  end

  describe 'DELETE #destroy_with_token_drop' do
    it 'resets the session' do
      delete :destroy_with_token_drop
      expect(session[:user_id]).to be_blank
    end

    it 'notifies the user they have signed out' do
      delete :destroy_with_token_drop
      expect(flash[:notice]).
        to eql(I18n.t('user.signed_out'))
    end

    it 'sets a session value' do
      expect {
        delete :destroy_with_token_drop
      }.to change{session.keys.sort}.by ["flash", "github.oauth.scope"]
    end
  end

  describe 'GET #failure' do
    before { get :failure }

    it { should respond_with(200) }
    it { should render_template('failure') }
  end
end
