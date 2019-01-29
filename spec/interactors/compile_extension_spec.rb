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
  end
end
