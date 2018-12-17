require 'spec_helper'

describe ApplicationHelper do
  describe '#auth_path' do
    context 'when using a symbol' do
      it 'returns the correct path' do
        expect(auth_path(:github)).to eq('/auth/github')
      end
    end

    context 'when using a string' do
      it 'returns the correct path' do
        expect(auth_path('github')).to eq('/auth/github')
      end
    end
  end

  describe '#posessivize' do
    it "should end in 's if the name does not end in s" do
      expect(posessivize('Black')).to eql "Black's"
    end

    it "should end in ' if the name ends in s" do
      expect(posessivize('Volkens')).to eql "Volkens'"
    end

    it 'should return an empty string when passed one' do
      expect(posessivize('')).to eql ''
    end

    it 'should return nil when passed nil' do
      expect(posessivize(nil)).to be_nil
    end
  end

  describe '#flash_message_class_for' do
    it 'should return a flass message class for notice flash messages' do
      expect(flash_message_class_for('notice')).to eql('success')
    end

    it 'should return a flass message class for alert flash messages' do
      expect(flash_message_class_for('alert')).to eql('alert')
    end

    it 'should return a flass message class for warning flash messages' do
      expect(flash_message_class_for('warning')).to eql('warning')
    end
  end

  describe '#supported_architectures' do
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

    before do
      ExtensionVersion.destroy_all
    end

    context 'no supported architectures' do
      it 'returns an empty array' do
        expect(supported_architectures).to eql []
      end
    end

    it 'includes architectures for viable builds' do
      expect {
        create :extension_version, config: config
      }.to change{supported_architectures.size}.by(2)
      expect(supported_architectures).to     include arch
      expect(supported_architectures).to     include arch2
      expect(supported_architectures).to_not include arch3
    end
  end

  describe '#supported_platforms' do
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

    before do
      ExtensionVersion.destroy_all
    end

    context 'no supported platforms' do
      it 'returns an empty array' do
        expect(supported_platforms).to eql []
      end
    end

    it 'includes platforms for viable builds' do
      expect {
        create :extension_version, config: config
      }.to change{supported_platforms.size}.by(2)
      expect(supported_platforms).to     include plat
      expect(supported_platforms).to     include plat2
      expect(supported_platforms).to_not include plat3
    end
  end

  describe '#advanced_options_available?' do
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

    before do
      ExtensionVersion.destroy_all
    end

    it 'returns a boolean' do
      expect(advanced_options_available?).to eql false
      create :extension_version, config: config
      expect(advanced_options_available?).to eql true
    end
  end
end
