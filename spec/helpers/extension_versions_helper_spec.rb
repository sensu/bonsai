require 'spec_helper'

describe ExtensionVersionsHelper do
  let(:config)            { {} }
  let(:extension_version) { build_stubbed :extension_version, config: config }

  describe "render_markdown" do
    it 'returns HTML for given markdown' do
      input = <<-CODE
# README

@calebhailey and @amdprophet bring the overwhelming power of Perl to Sensu.

<script type="text/javascript">alert("haxx")</script>

Closes #91.

Pending https://www.github.com/sensu/bonsai/issues/91.

```yaml
---
spec: idk
```

      CODE

      output = <<-CODE
<h1>README</h1>
<p><a href="/users/calebhailey" class="user-mention">@calebhailey</a> and <a href="/users/amdprophet" class="user-mention">@amdprophet</a> bring the overwhelming power of Perl to Sensu.</p>

<p>Closes <a href="https://www.github.com/my/repo/issues/91">#91</a>.</p>
<p>Pending <a href="https://www.github.com/sensu/bonsai/issues/91">sensu/bonsai#91</a>.</p>
<pre lang="yaml" class="highlight-yaml"><span style="color: #f4bf75">---</span>
<span style="color: #6a9fb5">spec</span><span style="color: #d0d0d0">:</span> <span style="color: #90a959">idk</span>
</pre>
      CODE
      output.chomp!

      expect(helper.render_document(input, "md", repo: "my/repo")).to eq(output.html_safe)
    end
  end

  describe "download_url_for" do
    it 'returns a GitHub URL' do
      expect(helper.download_url_for(extension_version)).to include "github.com"
    end
  end

  describe "gather_viable_release_assets" do
    context "version has no viable release assets" do
      it "returns an empty array" do
        expect(helper.gather_viable_release_assets(extension_version)).to be_empty
      end
    end

    context "version has a viable release asset" do
      before do
        extension_version.config = {"builds" => [{"viable"=>true, "asset_url" => "http://url.com"}]}
      end

      before do
        extension_version.config['builds'].each do |build|
          extension_version.release_assets << build(:release_asset,
            platform: build['platform'],
            arch: build['arch'],
            viable: build['viable'],
            source_asset_sha: build['asset_sha'],
            source_asset_url: build['asset_url'],
            source_sha_filename: build['sha_filename'],
            source_base_filename: build['base_filename'],
            source_asset_filename: build['asset_filename']
          )
        end
      end

      it "returns an array of ReleaseAsset objects" do
        result = helper.gather_viable_release_assets(extension_version)
        expect(result).to_not be_empty
        result.each do |obj|
          expect(obj).to be_a(ReleaseAsset)
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

      before do
        extension_version.config['builds'].each do |build|
          extension_version.release_assets << build(:release_asset,
            platform: build['platform'],
            arch: build['arch'],
            viable: build['viable'],
            source_asset_sha: build['asset_sha'],
            source_asset_url: build['asset_url'],
            source_sha_filename: build['sha_filename'],
            source_base_filename: build['base_filename'],
            source_asset_filename: build['asset_filename']
          )
        end
      end

      it "returns non-empty collections" do
        expect(subject).to eq [["linux", "OSX"], ["x86_64"]]
      end
    end
  end

  describe "extension_version_analyzed?" do
    subject { helper.extension_version_analyzed?(extension_version) }

    context 'Github-based extensions' do
      before do
        expect(extension_version).to_not be_hosted
      end

      it 'returns true' do
        expect(subject).to be_truthy
      end
    end

    context 'hosted extensions' do
      let(:extension)         { create :extension, :hosted }
      let(:extension_version) { extension.extension_versions.first }

      before do
        expect(extension_version).to be_hosted
      end

      context 'with no source file' do
        it 'returns false' do
          expect(subject).to be_falsey
        end
      end

      context 'with an analyzed source file' do
        let(:file_name)    { 'private-extension.tgz' }
        let(:file_path)    { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
        let(:attachable)   { fixture_file_upload(file_path) }
        let(:blob_hash)    { {
          io:           attachable.open,
          filename:     attachable.original_filename,
          content_type: attachable.content_type
        } }
        let(:blob)         { ActiveStorage::Blob.create_after_upload! blob_hash }

        before do
          extension_version.source_file.attach(blob)
        end

        context 'before analysis' do
          before do
            expect(extension_version.source_file).not_to be_analyzed
          end

          it 'returns false' do
            expect(subject).to be_falsey
          end
        end

        context 'after analysis' do
          before do
            extension_version.source_file.analyze
            extension_version.reload
            expect(extension_version.source_file).to be_analyzed
          end

          it 'returns false' do
            expect(subject).to be_truthy
          end
        end
      end
    end
  end
end
