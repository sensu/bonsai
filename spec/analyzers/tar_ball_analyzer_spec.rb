require "spec_helper"

describe TarBallAnalyzer do
  let(:file_name)    { 'sensu-particle-checks-dan.tgz' }
  let(:version_name) { '0.0.2' }
  let(:repo)         { 'sensu-particle-checks-dan' }
  let(:extension)    { create :extension, :hosted, name: repo }
  let(:version)      { create :extension_version, extension: extension, version: version_name }

  let(:file_path)  { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
  let(:attachable) { fixture_file_upload(file_path) }
  let(:blob_hash)  { {
    io:           attachable.open,
    filename:     attachable.original_filename,
    content_type: attachable.content_type
  } }
  let(:blob)       { ActiveStorage::Blob.create_after_upload! blob_hash }
  subject          { TarBallAnalyzer.new(blob) }

  before do
    Extension.destroy_all
  end

  describe '.accept?' do
    it { expect(TarBallAnalyzer.accept?(blob)).to be_truthy }
  end

  describe 'metadata' do
    let(:metadata) { subject.metadata }

    it 'includes the readme content' do
      expect(metadata[:readme]).to include '## Contributing'
    end

    it 'includes the extension' do
      expect(metadata[:readme_extension]).to eq 'md'
    end

    it 'includes the config data' do
      version.source_file.attach(blob)
      expect(metadata[:config]).to have_key "builds"
    end

    context 'readme file name has no extension' do
      let(:file_name) { 'readme-no-extension.tgz' }

      it 'includes the readme content' do
        expect(metadata[:readme]).to include 'License and Authors'
      end

      it 'excludes the extension' do
        expect(metadata.keys).to_not include :readme_extension
      end
    end

    context 'readme file name has zero length' do
      let(:file_name) { 'zero-length-readme.tgz' }

      it 'excludes the readme content' do
        expect(metadata.keys).to_not include :readme
      end

      it 'metadata is empty' do
        expect(metadata).to eq({readme_extension: "md"})
      end
    end

    context 'tar ball is corrupted' do
      let(:file_name) { 'corrupted-tarball.tgz' }

      it 'excludes the readme content' do
        expect(metadata.keys).to_not include :readme
      end

      it 'excludes the extension' do
        expect(metadata.keys).to_not include :readme_extension
      end
    end
  end

  context 'not a tar ball' do
    let(:file_name) { 'not-a-tarball.txt' }

    describe '.accept?' do
      it { expect(TarBallAnalyzer.accept?(blob)).to be_falsey }
    end
  end

  describe '#fetch_file' do
    it 'returns a string' do
      file = subject.fetch_file(file_path: 'particle_variable_metric_check/main.go')
      result = file.read
      expect(result).to be_a String
      expect(result.size).to eql 5107
    end

    context 'unknown file' do
      it 'returns nil' do
        expect(subject.fetch_file(file_path: 'not a file')).to eql nil
      end
    end
  end
end
