require 'spec_helper'

describe SyncExtensionContentsAtVersionsWorker do
  before do
    Account.destroy_all
  end

  let(:asset_hash1)  { {name: "my_repo-1.2.2-linux-x86_64.tar.gz",
                        browser_download_url: "https://example.com/download"} }
  let(:asset_hash2)  { {name: "my_repo-1.2.2-linux-x86_64.sha512.txt",
                        browser_download_url: "https://example.com/sha_download"} }
  let(:release_data) { {tag_name: version.version, assets: [asset_hash1, asset_hash2]} }
  let!(:version)     { create :extension_version }
  let(:extension)    { version.extension }
  
  subject            { SyncExtensionContentsAtVersionsWorker.new }

  before do
    FileUtils.mkdir_p extension.repo_path
    allow_any_instance_of(CmdAtPath).to receive(:cmd) { "" }
    allow_any_instance_of(Octokit::Client).to receive(:releases) { [release_data] }

    s3 = Aws::S3::Resource.new(
      access_key_id: ENV['AWS_S3_KEY_ID'],
      secret_access_key: ENV['AWS_S3_ACCESS_KEY'],
      region: ENV['AWS_S3_REGION']
    )
    @s3_bucket = s3.bucket(ENV['AWS_S3_ASSETS_BUCKET'])

    begin
      stub_aws unless @s3_bucket.exists?
    rescue
      stub_aws
    end
    

  end

  def stub_aws
    Aws::S3::Resource.any_instance.stub_chain(:bucket, :exists?).and_return(true)
    Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :exists?).and_return(true)
  end

  describe 'tag checking' do
    it 'honors semver tags' do
      tags = ["0.0.1"]   # is semver-conformant

      expect {
        subject.perform(extension, tags)
      }.to change{ExtensionVersion.count}.by 1
    end

    it 'ignores non-semver tags' do
      tags = ["v0.1A20180919"]  # is not semver-conformant

      expect {
        subject.perform(extension, tags)
      }.not_to change{ExtensionVersion.count}
    end
  end

  describe 'release note extraction' do
    let(:body)                  { "this is my body" }
    let(:release_infos_by_tag)  { {"0.33" => {"body" => body}} }
    let(:tags)                  { release_infos_by_tag.keys }

    it 'puts the release notes into the release notes field' do
      subject.perform(extension, tags, [], release_infos_by_tag)
      expect(extension.reload.extension_versions.last.release_notes).to eq body
    end
  end

  describe 'persist_assets' do
    let (:version) { create :extension_version_with_config }

    it 'creates release assets' do
      expect {
        subject.send(:persist_assets, version)
      }.to change{version.release_assets.count}.by(2)
    end
  end
end
