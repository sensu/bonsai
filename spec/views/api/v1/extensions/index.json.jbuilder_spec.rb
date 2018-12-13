require 'spec_helper'

describe 'api/v1/extensions/index' do
  let(:version1)       { create :extension_version }
  let(:version2)       { create :extension_version }
  let(:extension1)     { version1.extension }
  let(:extension2)     { version2.extension }

  before do
    assign(:extensions, [extension1, extension2])
    assign(:start, 69)
    assign(:total, 314)
    assign(:next_page_params, {start: 122})
    render
  end

  it "serializes the pagination info" do
    expect(json_body['start']).to eql(69)
    expect(json_body['total']).to eql(314)
    expect(json_body['next' ]).to match(/\/api\//)
    expect(json_body['next' ]).to match(/\/assets/)
    expect(json_body['next' ]).to match(/start=122/)
  end

  it "includes an array of extensions" do
    expect(json_body['assets']).to be_a(Array)
  end

  it "each extension includes an array of builds" do
    extensions = json_body['assets']
    expect(extensions).to be_many
    extensions.each do |extension|
      expect(extension['builds']).to be_a(Array)
    end
  end
end
