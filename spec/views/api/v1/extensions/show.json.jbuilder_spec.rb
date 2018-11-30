require 'spec_helper'

describe 'api/v1/extensions/show' do
  let(:version)       { create :extension_version }
  let(:extension)     { version.extension }

  before do
    assign(:extension, extension)
    render
  end

  it "serializes the extension name" do
    expect(json_body['name']).to eql("#{version.extension.owner_name}/#{version.extension.lowercase_name}")
  end

  it "serializes the url" do
    expect(json_body['description']).to be_present
    expect(json_body['description']).to eql(extension.description)
  end

  it "includes an array of builds" do
    expect(json_body['builds']).to be_a(Array)
  end
end
