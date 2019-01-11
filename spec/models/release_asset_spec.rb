require 'spec_helper'

describe ReleaseAsset do
  let(:extension) { build_stubbed :extension }
  let(:version)   { build_stubbed :extension_version, extension: extension }
  subject         { ReleaseAsset.new(version: version) }

  describe '.annotations' do
    context 'a hosted extension' do
      let(:extension) { build_stubbed :extension, :hosted }

      it 'includes a licensing message' do
        expect( subject.annotations.to_json).to match /license/i
      end
    end

    context 'a github extension' do
      let(:extension) { build_stubbed :extension }

      it 'includes a licensing message' do
        expect( subject.annotations.to_json).not_to match /license/i
      end
    end
  end
end
