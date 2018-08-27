require 'spec_feature_helper'

feature 'tools and extensions can be searched for' do
  let!(:extension) { create(:extension, name: 'apache') }
  #before { visit root_path }

  it 'returns results for extensions' do
    pending
    raise
    #within '.search_bar' do
    #  follow_relation 'toggle-search-types'
    #  follow_relation 'toggle-extension-search'
    #  fill_in 'q', with: 'apache'
    #  submit_form
    #end

    #expect(page).to have_content('apache')
    #expect(page).to have_no_content('.no-results')
  end
end
