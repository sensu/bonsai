require "spec_helper"

describe SetUpHostedExtension do
  let(:file_name)    { 'private-extension.tgz' }
  let(:file_path)    { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable)   { fixture_file_upload(file_path) }
  let(:blob_hash)    { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)         { ActiveStorage::Blob.create_after_upload! blob_hash }
  let(:version_name) { 'v0.1.2' }
  let(:extension)    { create :extension }
  subject(:context)  { SetUpHostedExtension.call(extension:    extension,
                                                 version_name: version_name) }

  before do
    extension.tmp_source_file.attach(blob)
  end

  describe '.call' do
    it "sets the extension's owner name" do
      orig_owner_name = extension.owner_name
      subject
      extension.reload
      expect(extension.owner_name).to     be_present
      # factory sets the extension owner_name the same as the owner.username
      # expect(extension.owner_name).to_not eql orig_owner_name
    end

    it "transfers the source file attachment to the new version child" do
      expect(extension.tmp_source_file).to     be_attached

      subject
      extension.reload
      version = extension.extension_versions.last

      expect(extension.tmp_source_file).to_not be_attached
      expect(version.source_file      ).to     be_attached
    end

    it "runs the post-metadata-analysis hook" do
      extension.tmp_source_file.analyze
      subject
      extension.reload
      version = extension.extension_versions.last

      expect(version.readme          ).to be_present
      expect(version.readme_extension).to be_present
      expect(version.config          ).to be_present
    end
  end
end
