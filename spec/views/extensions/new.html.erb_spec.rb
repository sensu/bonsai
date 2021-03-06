require 'spec_helper'

describe "extensions/new" do
  let(:extension) { create :extension }
  let(:user)      { create :user }

  before do
    sign_in user
    assign(:extension, Extension.new)
    allow(view).to receive(:policy) do |record|
      Pundit.policy(user, record)
    end
  end

  context "user is an admin" do
    let(:user)      { create :admin }

    it "displays a fieldset for uploading a ZIP file" do
      render
      expect(rendered).to have_selector('legend', text: "Upload a ZIP file")
    end
  end

  context "user is not an admin" do
    it "omits the fieldset for uploading a ZIP file" do
      render
      expect(rendered).not_to have_selector('legend', text: "Upload a ZIP file")
    end
  end
end
