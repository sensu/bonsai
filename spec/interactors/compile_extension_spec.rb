require "spec_helper"

describe CompileExtension do
  describe '.call' do
    subject { CompileExtension.call(extension: extension) }

    context 'with a GitHub-based extension' do
      let(:extension) { create :extension }

      it 'delegates to the SyncExtensionRepoWorker service class' do
        expect(SyncExtensionRepoWorker).to receive(:perform_async).with(extension.id)
        subject
      end
    end

    context 'with a hosted extension' do
      let(:extension)  { create :extension, :hosted, extension_versions_count: 0 }
      let!(:version1)  { create :extension_version, :with_source_file, extension: extension}
      let!(:version2)  { create :extension_version, :with_source_file, extension: extension}

      before do
        extension.reload
      end

      it 'schedules each version to be re-analyzed' do
        num_versions = extension.extension_versions.size
        expect(num_versions.size).to be > 0

        extension.extension_versions.map(&:source_file).map(&:blob).each do |blob|
          expect(blob).to receive(:analyze_later).exactly(1).times
        end
        subject
      end
    end
  end
end
