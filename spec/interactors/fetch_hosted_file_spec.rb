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
end
