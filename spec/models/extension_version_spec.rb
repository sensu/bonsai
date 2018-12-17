require 'spec_helper'

describe ExtensionVersion do
  subject { build_stubbed :extension_version }

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
end
