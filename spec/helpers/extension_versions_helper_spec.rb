require 'spec_helper'

describe ExtensionVersionsHelper do
  let(:extension_version) { build_stubbed :extension_version }

  describe "download_url_for" do
    it 'returns a GitHub URL' do
      expect(helper.download_url_for(extension_version)).to include "github.com"
    end
  end

  describe "gather_viable_release_assets" do
    context "version has no viable release assets" do
      it "returns an empty array" do
        expect(helper.gather_viable_release_assets(extension_version)).to be_a(Array)
        expect(helper.gather_viable_release_assets(extension_version)).to be_empty
      end
    end

    context "version has a viable release asset" do
      before do
        extension_version.config = {"builds" => [{"asset_url" => "http://url.com"}]}
      end

      it "returns an array of GithubAsset objects" do
        result = helper.gather_viable_release_assets(extension_version)

        expect(result).to be_a(Array)
        expect(result).to_not be_empty
        result.each do |obj|
          expect(obj).to be_a(GithubAsset)
        end
      end
    end
  end
end
