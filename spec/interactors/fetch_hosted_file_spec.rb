require "spec_helper"

describe FetchHostedFile do
  let(:file_name)  { 'private-extension.tgz' }
  let(:file_path)  { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable) { fixture_file_upload(file_path) }
  let(:blob_hash)  { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)        { ActiveStorage::Blob.create_after_upload! blob_hash }
  let(:target_path) { 'redis-test/recipes/default.rb' }
  subject(:context) { FetchHostedFile.call(blob: blob, file_path: target_path) }

  describe ".call" do
    context "file blob is not a compressed archive" do
      let(:file_name) { 'not-a-tarball.txt' }

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns a nil" do
        expect(context.content).to be_nil
      end
    end

    context "file blob is a tar ball" do
      let(:file_name) { 'private-extension.tgz' }

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns a string" do
        expect(context.content).to be_a String
        expect(context.content.size).to eql 136
      end
    end

    context "file blob is a zip file" do
      let(:file_name) { 'private-extension.zip' }

      it "succeeds" do
        expect(context).to be_a_success
      end

      it "returns a string" do
        expect(context.content).to be_a String
        expect(context.content.size).to eql 136
      end
    end
  end

  describe ".bulk_cache" do
    let(:file_name)    { 'sensu-particle-checks-dan.tgz' }
    let(:version_name) { '0.0.2' }
    let(:repo)         { 'sensu-particle-checks-dan' }
    let(:extension)    { create :extension, :hosted, name: repo }
    let(:version)      { create :extension_version, extension: extension, version: version_name }
    let(:file_paths)   { version.release_assets.map {|ra| version.interpolate_variables((ra.asset_filename))} }

    subject { FetchHostedFile.bulk_cache(extension_version: version, file_paths: file_paths) }

    before do
      Extension.destroy_all
      version.source_file.attach(blob)
      version.source_file.analyze
      version.reload
    end

    it "caches the files at the given paths" do
      file_paths.each do |file_path|
        key = FetchHostedFile.cache_key(blob: blob, file_path: file_path)
        expect(Rails.cache.fetch(key)).to be_nil
      end

      subject

      file_paths.each do |file_path|
        key = FetchHostedFile.cache_key(blob: blob, file_path: file_path)
        expect(Rails.cache.fetch(key)).to be_present
      end
    end
  end
end
