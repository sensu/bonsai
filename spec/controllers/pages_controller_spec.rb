require 'spec_helper'

describe PagesController do
  let(:user) { create(:user) }

  describe 'GET #dashboard' do
    context 'user is signed in' do
      before { sign_in user }

      it 'assigns extensions' do
        pending
        get :dashboard

        expect(assigns[:extensions]).to_not be_nil
      end

      it 'assigns collaborated extensions' do
        pending
        get :dashboard

        expect(assigns[:collaborated_extensions]).to_not be_nil
      end

      it 'assigns tools' do
        pending
        get :dashboard

        expect(assigns[:tools]).to_not be_nil
      end

      it '404s when requested with JSON' do
        pending
        # NOTE: this is a specific test for a more general scenario:
        # Supermarket fields a request to some action which only has an HTML
        # template. We define the correct behavior to be 404 Not Found.
        get :dashboard, params: {format: :json}

        expect(response).to render_template('exceptions/404.html.erb')
      end
    end

    context 'user is not signed in' do
      it 'redirects to the welcome page' do
        get :dashboard

        expect(response).to redirect_to(sign_in_path)
      end
    end
  end
end
