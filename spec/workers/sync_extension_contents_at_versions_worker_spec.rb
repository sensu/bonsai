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
  let!(:version)     { create :extension_version_with_config }
  let(:extension)    { version.extension }
  let(:user)         { create :user }
  
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

    # trap incorrect ENV variables (Travis) or no network connection
    #begin
    #  stub_aws unless @s3_bucket.exists?
    #rescue
      stub_aws
    #end
    
  end

  def stub_aws
    allow_any_instance_of(Aws::S3::Resource).to receive_message_chain('bucket.exists?') {true}
    allow_any_instance_of(Aws::S3::Resource).to receive_message_chain('bucket.object.exists?') {true}
    allow_any_instance_of(Aws::S3::Resource).to receive_message_chain('bucket.object.public_url') {'https://s3.us-west-2.amazonaws.com/bucket/example.com'}
    allow_any_instance_of(Aws::S3::Resource).to receive_message_chain('bucket.object.last_modified') {DateTime.now.to_s(:db)}
    allow_any_instance_of(Aws::S3::Resource).to receive_message_chain('bucket.object.delete') {true}
    allow_any_instance_of(Aws::S3::Resource).to receive_message_chain('bucket.object.put') {true}
    
    #Aws::S3::Resource.any_instance.stub_chain(:bucket, :exists?).and_return(true)
    #Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :exists?).and_return(true)
    #Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :public_url).and_return('https://s3.us-west-2.amazonaws.com/bucket/example.com')
    #Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :last_modified).and_return(DateTime.now.to_s(:db))
    #Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :delete).and_return(true)
    #Aws::S3::Resource.any_instance.stub_chain(:bucket, :object, :put).and_return(true)
  end

  describe 'tag checking' do
    it 'honors semver tags' do
      tags = ["0.0.1"]   # is semver-conformant

      expect {
        subject.perform(extension.id, tags, [], {}, user.id)
      }.to change{ExtensionVersion.count}.by 1
    end

    it 'ignores non-semver tags' do
      tags = ["v0.1A20180919"]  # is not semver-conformant

      expect {
        subject.perform(extension.id, tags, [], {}, user.id)
      }.not_to change{ExtensionVersion.count}
    end
  end

  describe 'release note extraction' do
    let(:body)                  { "this is my body" }
    let(:release_infos_by_tag)  { {"0.33" => {"body" => body}} }
    let(:tags)                  { release_infos_by_tag.keys }


    it 'puts the release notes into the release notes field' do
      subject.perform(extension.id, tags, [], release_infos_by_tag, user.id)
      expect(extension.reload.extension_versions.last.release_notes).to eq body
    end
  end

  describe 'annotations' do
    let(:config_hash) { version.config }
    let(:tags) { [version.version] }

    it 'adds prefix to config annotations' do
      config_hash['annotations'] = {
        'suggested_asset_url' => '/suggested/asset', 
        'suggested_asset_message' => 'Suggested Asset Messaage'
      }
      version.update_column(:config, config_hash)
      subject.perform(extension.id, tags, [], {}, user.id)
      version.reload
      annotations = version.config['annotations']
      expect(annotations.keys).to include('io.sensu.bonsai.suggested_asset_url')
    end

    it 'puts annotations in annotations field' do
      config_hash['annotations'] = {
        suggested_asset_url: '/suggested/asset',
        suggested_asset_message: 'Suggested Asset Message'
      }
      version.update_column(:config, config_hash)
      subject.perform(extension.id, tags, [], {}, user.id)
      version.reload
      annotations = version.annotations
      expect(annotations.map{|k,v| k.to_s}).to include('io.sensu.bonsai.suggested_asset_url')
    end

  end

  describe 'overrides' do 
    let(:config_hash) { version.config }
    let(:tags) { [version.version] }

    it 'loads an alternate readme file' do
      config_hash["overrides"] = [{
        "readme_url"=>"https://raw.githubusercontent.com/sensu/bonsai/master/README.md"
      }]
      version.update_column(:config, config_hash)
      subject.perform(extension.id, tags, [], {}, user.id)
      version.reload 
      expect(version.readme).to include('bonsai.sensu.io')
    end
      
    it 'corrects link to github to load readme file as markdown' do
      config_hash["overrides"] = [{
        "readme_url"=>"https://github.com/sensu/bonsai/blob/master/README.md"
      }]
      version.update_column(:config, config_hash)
      subject.perform(extension.id, tags, [], {}, user.id)
      version.reload 
      expect(version.readme).to include('bonsai.sensu.io')
    end

    it 'loads an alternate readme file based on extension override' do
      config_overrides = {
        "readme_url"=>"https://raw.githubusercontent.com/sensu/bonsai/master/README.md"
      }
      extension.update_column(:config_overrides, config_overrides)
      subject.perform(extension.id, tags, [], {}, user.id)
      version.reload 
      expect(version.readme).to include('bonsai.sensu.io')
    end

  end

end
