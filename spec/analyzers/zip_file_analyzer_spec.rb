require "spec_helper"

describe ZipFileAnalyzer do
  let(:file_name)  { 'private-extension.zip' }
  let(:file_path)  { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable) { fixture_file_upload(file_path) }
  let(:blob_hash)  { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)       { ActiveStorage::Blob.create_after_upload! blob_hash }
  subject          { ZipFileAnalyzer.new(blob) }

  describe '.accept?' do
    it { expect(ZipFileAnalyzer.accept?(blob)).to be_truthy }
  end

  describe 'metadata' do
    let(:metadata) { subject.metadata }

    it 'includes the readme content' do
      expect(metadata[:readme]).to include 'License and Authors'
    end

    it 'includes the extension' do
      expect(metadata[:readme_extension]).to eq 'md'
    end

    context 'readme file name has no extension' do
      let(:file_name) { 'readme-no-extension.zip' }

      it 'includes the readme content' do
        expect(metadata[:readme]).to include 'License and Authors'
      end

      it 'excludes the extension' do
        expect(metadata.keys).to_not include :readme_extension
      end
    end

    context 'readme file name has zero length' do
      let(:file_name) { 'zero-length-readme.zip' }

      it 'excludes the readme content' do
        expect(metadata.keys).to_not include :readme
      end

      it 'includes the extension' do
        expect(metadata[:readme_extension]).to eq 'md'
      end
    end

    context 'zipfile is corrupted' do
      let(:file_name) { 'corrupted-zipfile.zip' }

      it 'excludes the readme content' do
        expect(metadata.keys).to_not include :readme
      end

      it 'excludes the extension' do
        expect(metadata.keys).to_not include :readme_extension
      end
    end
  end

  context 'not a zip file' do
    let(:file_name) { 'not-a-zipfile.txt' }

    describe '.accept?' do
      it { expect(ZipFileAnalyzer.accept?(blob)).to be_falsey }
    end
  end
end
