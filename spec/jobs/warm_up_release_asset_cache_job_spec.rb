require 'rails_helper'

RSpec.describe WarmUpReleaseAssetCacheJob, type: :job do
  let(:file_path)    { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable)   { fixture_file_upload(file_path) }
  let(:blob_hash)    { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)         { ActiveStorage::Blob.create_after_upload! blob_hash }
  let(:file_name)    { 'sensu-particle-checks-dan.tgz' }
  let(:version_name) { '0.0.2' }
  let(:repo)         { 'sensu-particle-checks-dan' }
  let(:extension)    { create :extension, :hosted, name: repo }
  let(:version)      { create :extension_version, extension: extension, version: version_name }
  let(:file_paths)   { version.release_assets.map {|ra| version.interpolate_variables((ra.asset_filename))} }

  subject { WarmUpReleaseAssetCacheJob.perform_now(version) }

  before do
    Extension.destroy_all
  end

  context 'no attachment' do
    before do
      expect(version.source_file).to_not be_attached
    end

    it 'does nothing' do
      expect(FetchHostedFile).not_to receive(:bulk_cache)
      subject
    end
  end

  context 'with attachment' do
    before do
      version.source_file.attach(blob)
      version.source_file.analyze
      version.reload

      expect(version.source_file).to be_attached
    end

    it 'does a bulk cache' do
      expect(FetchHostedFile).to receive(:bulk_cache)
      subject
    end
  end
end
