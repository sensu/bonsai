require 'spec_helper'

describe ExtensionVersion do
  subject { build_stubbed :extension_version }

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
