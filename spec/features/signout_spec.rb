require 'spec_feature_helper'

describe 'signing out' do
  it 'displays a message about oc-id' do
    feature_sign_in(create(:user))
    feature_sign_out

    expect(page).to have_content('You have successfully signed out')
  end
end
