require 'spec_helper'

describe "extension_versions/new" do
  let(:extension)         { create :extension }
  let(:extension_version) { extension.extension_versions.build }
  let(:user)              { create :user }

  before do
    sign_in user
    assign(:extension_version, extension_version)
  end

  it "displays a fieldset for uploading a ZIP file" do
    render
    expect(rendered).to have_selector('legend', text: "Upload a ZIP file")
  end

  it "displays a version field" do
    render
    expect(rendered).to have_field("Version")
  end
end
