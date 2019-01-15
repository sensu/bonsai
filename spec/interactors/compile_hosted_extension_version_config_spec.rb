require "spec_helper"

describe CompileHostedExtensionVersionConfig do
  let(:file_name)    { 'sensu-particle-checks-dan.tgz' }
  let(:file_path)    { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable)   { fixture_file_upload(file_path) }
  let(:blob_hash)    { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)         { ActiveStorage::Blob.create_after_upload! blob_hash }
  let(:version)      { create :extension_version }

  describe ".call" do
    around(:each) do |example|
      version.source_file.attach(blob)
      version.with_file_finder do |finder|
        @result = CompileHostedExtensionVersionConfig.call(version: version, file_finder: finder)
        example.run
      end
    end

    it "succeeds" do
      expect(@result).to be_a_success
    end

    it "compiles the configuration" do
      data_hash = @result.data_hash
      expect(data_hash.keys.sort).to eql ['builds', 'description']

      builds = data_hash['builds']
      expect(builds.size).to eql 7
    end
  end
end
