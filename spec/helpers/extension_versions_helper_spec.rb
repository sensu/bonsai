require 'spec_helper'

describe ExtensionVersionsHelper do
  let(:extension_version) { build_stubbed :extension_version }

  describe "download_url_for" do
    it 'returns a GitHub URL' do
      expect(helper.download_url_for(extension_version)).to include "github.com"
    end
  end
end
