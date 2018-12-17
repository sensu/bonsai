require 'spec_helper'

describe ExtensionVersionsHelper do
  let(:config)            { {} }
  let(:extension_version) { build_stubbed :extension_version, config: config }

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
        extension_version.config = {"builds" => [{"viable"=>true, "asset_url" => "http://url.com"}]}
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

  describe "determine_viable_platforms_and_archs" do
    let(:platform) { nil }
    let(:arch)     { nil }
    subject        { helper.determine_viable_platforms_and_archs(extension_version, platform, arch) }

    context "version has no config" do
      before do
        expect(extension_version.config).to be_blank
      end

      it "returns empty collections" do
        expect(subject).to eq [[], []]
      end
    end

    context "version has a config" do
      let(:config)       { {"builds"=>
                              [{"arch"=>"x86_64",
                                "filter"=>
                                  ["System.OS == linux",
                                   "(System.Arch == x86_64) || (System.Arch == amd64)"],
                                "platform"=>"linux",
                                "viable"=>true,
                                "asset_url"=>"http://asset.url/",
                                "sha_filename"=>"test_asset-\#{version}-linux-x86_64.sha512.txt",
                                "asset_filename"=>"test_asset-\#{version}-linux-x86_64.tar.gz"},
                               {"arch"=>"x86_64",
                                "filter"=>
                                  ["System.OS == linux",
                                   "(System.Arch == x86_64) || (System.Arch == amd64)"],
                                "platform"=>"OSX",
                                "viable"=>true,
                                "asset_url"=>"http://asset.url/",
                                "sha_filename"=>"test_asset-\#{version}-OSX-x86_64.sha512.txt",
                                "asset_filename"=>"test_asset-\#{version}-OSX-x86_64.tar.gz"},]} }

      before do
        expect(extension_version.config).to be_present
      end

      it "returns non-empty collections" do
        expect(subject).to eq [["linux", "OSX"], ["x86_64"]]
      end
    end
  end
end
