require 'spec_helper'

describe ProfileController do
  let(:user) { create(:user) }

  describe 'PATCH #update' do
    context 'user is authenticated' do
      before { sign_in user }

      it 'updates the user' do
        pending
        patch :update, params: {
          user: {
            first_name: 'Bob',
            last_name:  'Loblaw'
          }
        }
        user.reload

        expect(user.name).to eql('Bob Loblaw')
      end

      it 'redirects to the user profile' do
        pending
        patch :update, params: {user: { first_name: 'Blob' }}

        expect(response).to redirect_to(user)
      end

      it 'uses strong parameters' do
        pending
        fake_user = double(User)
        attrs = {
          'email' => 'bob@example.com',
          'first_name' => 'Bob',
          'last_name' => 'Smith',
          'company' => 'Acme',
          'twitter_username' => 'bobbo',
          'irc_nickname' => 'bobbo',
          'jira_username' => 'bobbo',
          'email_preferences_attributes' => {
            '0' => {
              '_destroy' => '0',
              'system_email_id' => '2'
            },
            '1' => {
              '_destroy' => '1',
              'system_email_id' => '3'
            },
            '2' => {
              '_destroy' => '0',
              'system_email_id' => '1'
            }
          }
        }

        expect(fake_user).to receive(:update_attributes).with(attrs)
        allow(controller).to receive(:current_user) { fake_user }

        patch :update, params: {user: attributes_for(:user, attrs)}
      end
    end

  end

  describe 'GET #edit' do
    context 'user is authenticated' do
      before { sign_in user }

      it 'shows the edit form' do
        pending
        get :edit

        expect(response).to render_template('edit')
      end

      it 'assigns pending requests' do
        pending
        get :edit

        expect(assigns[:pending_requests]).to_not be_nil
      end
    end

  end

end
