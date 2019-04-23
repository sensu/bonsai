require 'spec_helper'

describe ReleaseAssetsController do
  render_views

  let(:platform)       { "linux" }
  let(:arch)           { "x86_64" }
  let(:sha_filename)   { "test_asset-\#{version}-linux-x86_64.sha512.txt" }
  let(:asset_filename) { "test_asset-\#{version}-linux-x86_64.tar.gz" }
  let(:config)         { {"builds" =>
                            [{"arch"           => arch,
                              "filter"         =>
                                ["System.OS == linux",
                                 "(System.Arch == x86_64) || (System.Arch == amd64)"],
                              "platform"       => platform,
                              "sha_filename"   => sha_filename,
                              "asset_filename" => asset_filename,
                              "viable"         => true,
                              "asset_url"      => "https://example.com/download",
                              "base_filename"  => 'foo.baz',
                              "asset_sha"      => "c1ec2f493f0ff9d83914c1ec2f493f0ff9d83914"}]} }
  let!(:version)       { create :extension_version, config: config }

  before do 
    version.config['builds'].each do |build|
      version.release_assets << build(:release_asset,
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

  let(:file_name)  { 'private-extension.tgz' }
  let(:file_path)  { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable) { fixture_file_upload(file_path) }
  let(:blob_hash)  { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)       { ActiveStorage::Blob.create_after_upload! blob_hash }

  describe 'GET #download' do
    it 'succeeds' do
      get :download,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response).to be_successful
      #expect(JSON.parse(response.body)).to be_a(Hash)
      expect(YAML.load(response.body)).to be_a(Hash)
    end

    it 'returns a file attachment' do
      get :download,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response.headers['Content-Disposition']).to match /attachment;/
      expect(response.headers['Content-Disposition']).to match /filename=/
    end

    #it 'returns a JSON stream' do
    it 'returns a YAML stream' do
      get :download,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      #streamed_data = JSON.parse(response.stream.body)
      streamed_data = YAML.load(response.stream.body)
      expect(streamed_data).to be_a(Hash)
      expect(streamed_data.keys).to include 'api_version'
    end
  end

  describe 'GET #asset_file' do
    let!(:version)       { create :extension_version, config: config }
    let(:asset_filename) { 'redis-test/metadata.rb' }

    before do
      version.source_file.attach(blob)
    end

    it 'succeeds' do
      get :asset_file,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response).to be_successful
    end

    it 'returns a file attachment' do
      get :asset_file,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response.headers['Content-Disposition']).to match /attachment;/
      expect(response.headers['Content-Disposition']).to match /filename=/
    end
  end

  describe 'GET #sha_file' do
    let!(:version)     { create :extension_version, config: config }
    let(:sha_filename) { 'redis-test/README.md' }

    before do
      version.source_file.attach(blob)
    end

    it 'succeeds' do
      get :sha_file,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response).to be_successful
    end

    it 'returns a file attachment' do
      get :sha_file,
          params: {extension_id: version.extension,
                   username:     version.extension.owner_name,
                   version:      version,
                   platform:     platform,
                   arch:         arch}
      expect(response.headers['Content-Disposition']).to match /attachment;/
      expect(response.headers['Content-Disposition']).to match /filename=/
    end
  end
end
