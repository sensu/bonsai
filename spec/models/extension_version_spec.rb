require 'spec_helper'

describe ExtensionVersion do
  subject { build_stubbed :extension_version }

  describe '.active' do
    let!(:enabled_extension)  { create :extension }
    let!(:disabled_extension) { create :extension, :disabled }

    it 'includes versions belonging to enabled extensions' do
      expect {
        create :extension_version, extension: enabled_extension
      }.to change{ExtensionVersion.active.count}.by(1)
    end

    it 'ignores versions belonging to disabled extensions' do
      expect {
        create :extension_version, extension: disabled_extension
      }.not_to change{ExtensionVersion.active.count}
    end
  end

  describe '.for_architectures' do
    let(:arch)   { 'my-arch' }
    let(:arch2)  { 'other-arch' }
    let(:arch3)  { 'uninteresting-arch' }
    let(:viable) { true }
    let(:config) do
      {'builds' => [
        {"viable" => viable,
         "arch"   => arch},
        {"viable" => viable,
         "arch"   => arch2},
      ]}
    end

    context 'build is viable' do
      it 'includes versions with viable builds for the target architecture' do
        expect {
          create :extension_version, config: config
        }.to change{ExtensionVersion.for_architectures([arch]).count}.by(1)

        expect {
          create :extension_version, config: config
        }.to change{ExtensionVersion.for_architectures([arch2]).count}.by(1)
      end

      it 'does not double-count versions that have more than one matching architecture' do
        expect {
          create :extension_version, config: config
        }.to change{ExtensionVersion.for_architectures([arch, arch2]).count}.by(1)
      end

      it 'ignores viable versions that do not have one of the target architectures' do
        expect {
          create :extension_version, config: config
        }.to_not change{ExtensionVersion.for_architectures([arch3]).count}
      end
    end

    context 'build is not viable' do
      let(:viable) { false }

      it 'ignores versions that are not viable' do
        expect {
          create :extension_version, config: config
        }.to_not change{ExtensionVersion.for_architectures([arch]).count}

        expect {
          create :extension_version, config: config
        }.to_not change{ExtensionVersion.for_architectures([arch2]).count}
      end
    end
  end

  describe '.for_platforms' do
    let(:plat)   { 'my-plat' }
    let(:plat2)  { 'other-plat' }
    let(:plat3)  { 'uninteresting-plat' }
    let(:viable) { true }
    let(:config) do
      {'builds' => [
        {"viable"   => viable,
         "platform" => plat},
        {"viable"   => viable,
         "platform" => plat2},
      ]}
    end

    context 'build is viable' do
      it 'includes versions with viable builds for the target platform' do
        expect {
          create :extension_version, config: config
        }.to change{ExtensionVersion.for_platforms([plat]).count}.by(1)

        expect {
          create :extension_version, config: config
        }.to change{ExtensionVersion.for_platforms([plat2]).count}.by(1)
      end

      it 'does not double-count versions that have more than one matching platform' do
        expect {
          create :extension_version, config: config
        }.to change{ExtensionVersion.for_platforms([plat, plat2]).count}.by(1)
      end

      it 'ignores viable versions that do not have one of the target platforms' do
        expect {
          create :extension_version, config: config
        }.to_not change{ExtensionVersion.for_platforms([plat3]).count}
      end
    end

    context 'build is not viable' do
      let(:viable) { false }

      it 'ignores versions that are not viable' do
        expect {
          create :extension_version, config: config
        }.to_not change{ExtensionVersion.for_platforms([plat]).count}

        expect {
          create :extension_version, config: config
        }.to_not change{ExtensionVersion.for_platforms([plat2]).count}
      end
    end
  end

  describe '#metadata' do
    context 'no source file' do
      before do
        expect(subject.source_file).to_not be_attached
      end

      it 'returns an empty hash' do
        expect(subject.metadata).to eq({})
      end
    end

    context 'with source file' do
      subject { create :extension_version, :with_source_file }

      before do
        expect(subject.source_file).to be_attached
      end

      it 'returns a non-empty hash' do
        expect(subject.metadata).to be_kind_of(Hash)
        expect(subject.metadata).to be_present
      end
    end
  end

  describe '#interpolate_variables' do
    let(:version_name) { "1.2.2"}
    let(:repo_name)    { "my_repo" }
    let(:extension)    { create :extension, extension_versions_count: 0, github_url: "https://github.com/owner/#{repo_name}" }
    let(:version)      { build :extension_version, extension: extension, version: version_name }
    let(:raw_string)   { '  this #{repo} is #{version} wert      '}
    subject            { version.interpolate_variables(raw_string) }

    it {expect(subject).to eql "  this my_repo is 1.2.2 wert      "}

    describe 'a nil input string' do
      let(:raw_string) { nil }

      it 'returns a nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#after_attachment_analysis' do
    let(:file_name)  { 'private-extension.tgz' }
    let(:file_path)  { Rails.root.join('spec', 'support', 'extension_fixtures', file_name) }
    let(:attachable) { fixture_file_upload(file_path) }
    let(:blob_hash)  { {
      io:           attachable.open,
      filename:     attachable.original_filename,
      content_type: attachable.content_type
    } }
    let(:blob)       { ActiveStorage::Blob.create_after_upload! blob_hash }
    subject          { create :extension_version, readme_extension: 'txt' }

    it "updates the version's metadata" do
      orig_readme     = subject.readme
      orig_readme_ext = subject.readme_extension
      orig_config     = subject.config

      subject.source_file.attach(blob)
      subject.source_file.analyze
      subject.reload
      expect(subject.source_file).to be_attached

      expect(subject.readme          ).to be_present
      expect(subject.readme_extension).to be_present
      expect(subject.config          ).to be_present

      expect(subject.readme          ).not_to eql orig_readme
      expect(subject.readme_extension).not_to eql orig_readme_ext
      expect(subject.config          ).not_to eql orig_config
    end
  end
end
