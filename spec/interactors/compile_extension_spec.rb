require "spec_helper"

describe CompileExtension do
  describe '.call' do
    subject { CompileExtension.call(extension: extension) }

    context 'with a GitHub-based extension' do
      let(:extension) { create :extension }

      it 'delegates to the wprler' do
        expect(SetupCompileGithubExtensionWorker).to receive(:perform_async).with(extension.id)
        subject
      end
    end

    context 'with a hosted extension' do
      let(:extension)  { create :extension, :hosted, extension_versions_count: 0 }

      it 'delegates to the wprker' do
        expect(SetupCompileHostedExtensionWorker).to receive(:perform_async).with(extension.id)
        subject
      end
    end
  end
end
